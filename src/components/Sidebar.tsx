import { useState } from 'react';
import { Chat, User } from '../types';
import { USERS } from '../data/mockData';
import { formatChatTime } from '../utils/time';
import { cn } from '../utils/cn';

interface Props {
  chats: Chat[];
  currentUser: User;
  activeChatId: string | null;
  onSelectChat: (chatId: string) => void;
  onOpenSettings: () => void;
  onNewChat: () => void;
}

export default function Sidebar({ chats, currentUser, activeChatId, onSelectChat, onOpenSettings, onNewChat }: Props) {
  const [search, setSearch] = useState('');

  const filtered = chats.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase())
  );

  const pinned = filtered.filter(c => c.pinned);
  const regular = filtered.filter(c => !c.pinned);

  const getUserStatus = (chat: Chat) => {
    if (chat.type === 'group') return null;
    const otherId = chat.members.find(m => m !== 'me');
    return USERS.find(u => u.id === otherId)?.status || null;
  };

  const renderChat = (chat: Chat) => {
    const status = getUserStatus(chat);
    const isActive = chat.id === activeChatId;
    const lastMsg = chat.lastMessage;
    const preview = lastMsg
      ? lastMsg.senderId === 'me'
        ? `Вы: ${lastMsg.text}`
        : lastMsg.text
      : 'Нет сообщений';

    return (
      <button
        key={chat.id}
        onClick={() => onSelectChat(chat.id)}
        className={cn(
          'w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all text-left active:scale-98',
          isActive ? 'chat-item-active' : 'chat-item'
        )}
        style={{
          background: isActive ? 'var(--accent-soft)' : 'transparent',
        }}
      >
        {/* Avatar */}
        <div className="relative flex-shrink-0">
          <div className="w-12 h-12 rounded-full flex items-center justify-center text-2xl font-medium"
            style={{ background: 'var(--input-bg)' }}>
            {chat.avatar}
          </div>
          {status === 'online' && (
            <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full border-2"
              style={{ background: '#22c55e', borderColor: 'var(--sidebar-bg)' }} />
          )}
          {status === 'away' && (
            <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full border-2"
              style={{ background: '#f59e0b', borderColor: 'var(--sidebar-bg)' }} />
          )}
          {chat.pinned && (
            <span className="absolute -top-1 -right-1 text-xs">📌</span>
          )}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-1">
            <span className="font-semibold text-sm truncate" style={{ color: 'var(--text-primary)' }}>
              {chat.name}
            </span>
            <div className="flex items-center gap-1 flex-shrink-0">
              {chat.muted && <span className="text-xs opacity-50">🔇</span>}
              {lastMsg && (
                <span className="text-xs" style={{ color: 'var(--text-muted)' }}>
                  {formatChatTime(lastMsg.timestamp)}
                </span>
              )}
            </div>
          </div>
          <div className="flex items-center justify-between gap-1 mt-0.5">
            <p className="text-xs truncate" style={{ color: 'var(--text-secondary)' }}>
              {preview.length > 40 ? preview.slice(0, 40) + '…' : preview}
            </p>
            {chat.unread > 0 && (
              <span className="flex-shrink-0 min-w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold text-white px-1"
                style={{ background: chat.muted ? 'var(--text-muted)' : 'var(--accent)' }}>
                {chat.unread > 99 ? '99+' : chat.unread}
              </span>
            )}
          </div>
        </div>
      </button>
    );
  };

  return (
    <div className="h-full flex flex-col" style={{ background: 'var(--sidebar-bg)' }}>
      {/* Header */}
      <div className="flex items-center justify-between px-4 pt-4 pb-2 flex-shrink-0">
        <h1 className="text-xl font-bold" style={{ color: 'var(--text-primary)' }}>Connecta</h1>
        <div className="flex items-center gap-1">
          <button
            onClick={onNewChat}
            className="w-9 h-9 rounded-xl flex items-center justify-center transition-all active:scale-90 text-lg"
            style={{ color: 'var(--accent)', background: 'var(--accent-soft)' }}
            title="Новый чат"
          >
            ✏️
          </button>
        </div>
      </div>

      {/* Search */}
      <div className="px-3 pb-3 flex-shrink-0">
        <div className="flex items-center gap-2 px-3 rounded-xl"
          style={{ background: 'var(--input-bg)' }}>
          <span className="text-base" style={{ color: 'var(--text-muted)' }}>🔍</span>
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Поиск"
            className="flex-1 py-2.5 text-sm bg-transparent outline-none"
            style={{ color: 'var(--text-primary)' }}
          />
          {search && (
            <button onClick={() => setSearch('')} className="text-sm" style={{ color: 'var(--text-muted)' }}>✕</button>
          )}
        </div>
      </div>

      {/* Chat list */}
      <div className="flex-1 overflow-y-auto px-2 space-y-0.5">
        {pinned.length > 0 && (
          <>
            {pinned.map(renderChat)}
            {regular.length > 0 && (
              <div className="px-2 py-1">
                <div className="h-px" style={{ background: 'var(--border)' }} />
              </div>
            )}
          </>
        )}
        {regular.map(renderChat)}
        {filtered.length === 0 && (
          <div className="flex flex-col items-center justify-center py-12 space-y-2">
            <span className="text-4xl">🔍</span>
            <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Ничего не найдено</p>
          </div>
        )}
      </div>

      {/* Bottom: user profile */}
      <div className="flex-shrink-0 px-2 py-2 border-t" style={{ borderColor: 'var(--border)' }}>
        <button
          onClick={onOpenSettings}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all active:scale-95"
          style={{ color: 'var(--text-primary)' }}
          onMouseEnter={e => (e.currentTarget.style.background = 'var(--accent-soft)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
        >
          <div className="relative w-10 h-10 rounded-full flex items-center justify-center text-xl flex-shrink-0"
            style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}>
            {currentUser.avatar}
            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full border-2"
              style={{ background: '#22c55e', borderColor: 'var(--sidebar-bg)' }} />
          </div>
          <div className="flex-1 min-w-0 text-left">
            <p className="text-sm font-semibold truncate" style={{ color: 'var(--text-primary)' }}>{currentUser.name}</p>
            <p className="text-xs" style={{ color: 'var(--text-muted)' }}>@{currentUser.username}</p>
          </div>
          <span className="text-lg" style={{ color: 'var(--text-muted)' }}>⚙️</span>
        </button>
      </div>
    </div>
  );
}
