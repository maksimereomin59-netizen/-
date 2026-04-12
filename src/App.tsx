import { useState, useCallback, useEffect } from 'react';
import { Chat, Message, User, Theme } from './types';
import { CHATS, MESSAGES, CURRENT_USER } from './data/mockData';
import WelcomeScreen from './components/WelcomeScreen';
import Sidebar from './components/Sidebar';
import ChatArea from './components/ChatArea';
import SettingsPanel from './components/SettingsPanel';
import EmptyState from './components/EmptyState';
import NewChatModal from './components/NewChatModal';

type MobileView = 'sidebar' | 'chat' | 'settings';

export default function App() {
  const [isRegistered, setIsRegistered] = useState(false);
  const [currentUser, setCurrentUser] = useState<User>(CURRENT_USER);
  const [theme, setTheme] = useState<Theme>('dark');
  const [chats, setChats] = useState<Chat[]>(CHATS);
  const [messages, setMessages] = useState<Message[]>(MESSAGES);
  const [activeChatId, setActiveChatId] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [showNewChat, setShowNewChat] = useState(false);
  const [mobileView, setMobileView] = useState<MobileView>('sidebar');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const activeChat = chats.find(c => c.id === activeChatId) || null;

  const handleSelectChat = useCallback((chatId: string) => {
    setActiveChatId(chatId);
    setShowSettings(false);
    setChats(prev => prev.map(c => c.id === chatId ? { ...c, unread: 0 } : c));
    setMobileView('chat');
  }, []);

  const handleBack = useCallback(() => {
    setMobileView('sidebar');
    setActiveChatId(null);
  }, []);

  const handleOpenSettings = useCallback(() => {
    setShowSettings(true);
    setActiveChatId(null);
    setMobileView('settings');
  }, []);

  const handleCloseSettings = useCallback(() => {
    setShowSettings(false);
    setMobileView('sidebar');
  }, []);

  const handleAddMessage = useCallback((chatId: string, text: string, replyTo?: string) => {
    const newMsg: Message = {
      id: `msg_${Date.now()}`,
      chatId,
      senderId: 'me',
      text,
      timestamp: new Date(),
      reactions: [],
      replyTo,
      type: 'text',
    };
    setMessages(prev => [...prev, newMsg]);
    setChats(prev => prev.map(c =>
      c.id === chatId ? { ...c, lastMessage: newMsg } : c
    ));

    // Get other member for simulated reply
    const chat = chats.find(c => c.id === chatId);
    if (!chat) return;
    const otherMemberId = chat.members.find(m => m !== 'me');
    if (!otherMemberId) return;

    const replies = [
      'Понял, спасибо! 👌', 'Хорошо 👍', 'Окей!', 'Договорились!',
      'Отлично!', '😊', 'Интересно!', 'Согласен', 'Понятно!', 'Буду иметь в виду 🙏',
    ];
    const delay = 1000 + Math.random() * 2500;

    setTimeout(() => {
      const replyMsg: Message = {
        id: `msg_${Date.now()}_r`,
        chatId,
        senderId: otherMemberId,
        text: replies[Math.floor(Math.random() * replies.length)],
        timestamp: new Date(),
        reactions: [],
        type: 'text',
      };
      setMessages(prev => [...prev, replyMsg]);
      setChats(prev => prev.map(c => {
        if (c.id !== chatId) return c;
        return { ...c, lastMessage: replyMsg, unread: activeChatId === chatId ? 0 : c.unread + 1 };
      }));
    }, delay);
  }, [chats, activeChatId]);

  const handleReact = useCallback((msgId: string, emoji: string) => {
    setMessages(prev => prev.map(msg => {
      if (msg.id !== msgId) return msg;
      const existingIdx = msg.reactions.findIndex(r => r.emoji === emoji);
      const newReactions = [...msg.reactions];

      if (existingIdx >= 0) {
        const r = newReactions[existingIdx];
        if (r.users.includes('me')) {
          const newUsers = r.users.filter(u => u !== 'me');
          if (newUsers.length === 0) {
            newReactions.splice(existingIdx, 1);
          } else {
            newReactions[existingIdx] = { ...r, count: r.count - 1, users: newUsers };
          }
        } else {
          newReactions[existingIdx] = { ...r, count: r.count + 1, users: [...r.users, 'me'] };
        }
      } else {
        newReactions.push({ emoji, count: 1, users: ['me'] });
      }
      return { ...msg, reactions: newReactions };
    }));
  }, []);

  const handleCreateChat = useCallback((chat: Chat) => {
    setChats(prev => [chat, ...prev]);
  }, []);

  if (!isRegistered) {
    return <WelcomeScreen onComplete={(user) => { setCurrentUser(user); setIsRegistered(true); }} />;
  }

  // Desktop sidebar content
  const SidebarContent = () => showSettings ? (
    <SettingsPanel
      currentUser={currentUser}
      theme={theme}
      onClose={handleCloseSettings}
      onUpdateUser={setCurrentUser}
      onChangeTheme={setTheme}
    />
  ) : (
    <Sidebar
      chats={chats}
      currentUser={currentUser}
      activeChatId={activeChatId}
      onSelectChat={handleSelectChat}
      onOpenSettings={handleOpenSettings}
      onNewChat={() => setShowNewChat(true)}
    />
  );

  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', overflow: 'hidden', background: 'var(--bg)' }}>

      {/* ===== DESKTOP LAYOUT ===== */}
      {/* Sidebar column (always visible on desktop) */}
      <div
        className="hidden md:flex flex-col flex-shrink-0 border-r"
        style={{ width: 320, borderColor: 'var(--border)' }}
      >
        <SidebarContent />
      </div>

      {/* Main chat area (desktop) */}
      <div className="hidden md:flex flex-1 flex-col min-w-0">
        {activeChat ? (
          <ChatArea
            key={activeChatId!}
            chat={activeChat}
            messages={messages}
            currentUser={currentUser}
            onBack={handleBack}
            onAddMessage={handleAddMessage}
            onReact={handleReact}
            onOpenInfo={() => {}}
          />
        ) : (
          <EmptyState />
        )}
      </div>

      {/* ===== MOBILE LAYOUT ===== */}
      {/* Mobile: Sidebar view */}
      {mobileView === 'sidebar' && (
        <div className="md:hidden flex flex-col" style={{ width: '100%', height: '100%' }}>
          <Sidebar
            chats={chats}
            currentUser={currentUser}
            activeChatId={activeChatId}
            onSelectChat={handleSelectChat}
            onOpenSettings={handleOpenSettings}
            onNewChat={() => setShowNewChat(true)}
          />
        </div>
      )}

      {/* Mobile: Settings view */}
      {mobileView === 'settings' && (
        <div className="md:hidden flex flex-col" style={{ width: '100%', height: '100%' }}>
          <SettingsPanel
            currentUser={currentUser}
            theme={theme}
            onClose={handleCloseSettings}
            onUpdateUser={setCurrentUser}
            onChangeTheme={setTheme}
          />
        </div>
      )}

      {/* Mobile: Chat view */}
      {mobileView === 'chat' && activeChat && (
        <div className="md:hidden flex flex-col" style={{ width: '100%', height: '100%' }}>
          <ChatArea
            key={activeChatId!}
            chat={activeChat}
            messages={messages}
            currentUser={currentUser}
            onBack={handleBack}
            onAddMessage={handleAddMessage}
            onReact={handleReact}
            onOpenInfo={() => {}}
          />
        </div>
      )}

      {/* New chat modal */}
      {showNewChat && (
        <NewChatModal
          existingChats={chats}
          onClose={() => setShowNewChat(false)}
          onSelectChat={handleSelectChat}
          onCreateChat={handleCreateChat}
        />
      )}
    </div>
  );
}
