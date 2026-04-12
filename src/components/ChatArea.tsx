import { useState, useRef, useEffect, useCallback } from 'react';
import { Chat, Message, User } from '../types';
import { USERS } from '../data/mockData';
import { formatDate } from '../utils/time';
import MessageBubble from './MessageBubble';
import ChatHeader from './ChatHeader';

interface Props {
  chat: Chat;
  messages: Message[];
  currentUser: User;
  onBack: () => void;
  onAddMessage: (chatId: string, text: string, replyTo?: string) => void;
  onReact: (msgId: string, emoji: string) => void;
  onOpenInfo: () => void;
}

export default function ChatArea({ chat, messages, currentUser, onBack, onAddMessage, onReact, onOpenInfo }: Props) {
  const [input, setInput] = useState('');
  const [replyTo, setReplyTo] = useState<Message | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);

  const chatMessages = messages.filter(m => m.chatId === chat.id);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatMessages.length]);

  useEffect(() => {
    inputRef.current?.focus();
  }, [chat.id]);

  const handleSend = useCallback(() => {
    const text = input.trim();
    if (!text) return;
    onAddMessage(chat.id, text, replyTo?.id);
    setInput('');
    setReplyTo(null);
    inputRef.current?.focus();
  }, [input, chat.id, replyTo, onAddMessage]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);
    // Auto-resize textarea
    const ta = e.target;
    ta.style.height = 'auto';
    ta.style.height = Math.min(ta.scrollHeight, 120) + 'px';
  };

  // Group messages by date
  const groupedMessages: { date: string; messages: Message[] }[] = [];
  chatMessages.forEach(msg => {
    const dateStr = formatDate(msg.timestamp);
    const last = groupedMessages[groupedMessages.length - 1];
    if (last && last.date === dateStr) {
      last.messages.push(msg);
    } else {
      groupedMessages.push({ date: dateStr, messages: [msg] });
    }
  });

  const getReplyPreview = (replyId: string) => {
    const msg = messages.find(m => m.id === replyId);
    if (!msg) return null;
    const sender = msg.senderId === 'me' ? 'Вы' : USERS.find(u => u.id === msg.senderId)?.name || 'Неизвестно';
    return { sender, text: msg.text };
  };

  // Background pattern
  const bgPatternStyle = {
    background: 'var(--chat-bg)',
    backgroundImage: `radial-gradient(circle, var(--bg-pattern-color) 1px, transparent 1px)`,
    backgroundSize: '24px 24px',
  };

  return (
    <div className="flex flex-col h-full">
      <ChatHeader chat={chat} currentUser={currentUser} onBack={onBack} onOpenInfo={onOpenInfo} />

      {/* Messages */}
      <div
        ref={messagesContainerRef}
        className="flex-1 overflow-y-auto px-3 py-4 space-y-1"
        style={bgPatternStyle}
      >
        {chatMessages.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full space-y-3 opacity-60">
            <span className="text-5xl">{chat.avatar}</span>
            <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Начните общение прямо сейчас!</p>
          </div>
        )}

        {groupedMessages.map(group => (
          <div key={group.date} className="space-y-1">
            {/* Date separator */}
            <div className="flex justify-center py-2">
              <span className="text-xs px-3 py-1 rounded-full" style={{ background: 'var(--bubble-system)', color: 'var(--text-secondary)' }}>
                {group.date}
              </span>
            </div>
            {group.messages.map((msg, idx) => {
              const isOwn = msg.senderId === 'me';
              const _prevMsg = group.messages[idx - 1]; void _prevMsg;

              return (
                <div key={msg.id} className="space-y-0.5">
                  {/* Reply preview */}
                  {msg.replyTo && (() => {
                    const reply = getReplyPreview(msg.replyTo);
                    if (!reply) return null;
                    return (
                      <div className={`flex ${isOwn ? 'justify-end' : 'justify-start'} px-1`}>
                        <div className="max-w-[60%] px-3 py-1.5 rounded-xl border-l-2 text-xs opacity-70"
                          style={{ borderColor: 'var(--accent)', background: 'var(--bubble-reply)', color: 'var(--text-secondary)' }}>
                          <span className="font-semibold block" style={{ color: 'var(--accent)' }}>{reply.sender}</span>
                          <span className="truncate block">{reply.text}</span>
                        </div>
                      </div>
                    );
                  })()}
                  <MessageBubble
                    message={msg}
                    isOwn={isOwn}
                    isGroup={chat.type === 'group'}
                    onReact={onReact}
                    onReply={setReplyTo}
                  />
                </div>
              );
            })}
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      {/* Input area */}
      <div className="flex-shrink-0 border-t" style={{ background: 'var(--header-bg)', borderColor: 'var(--border)' }}>
        {/* Reply bar */}
        {replyTo && (
          <div className="flex items-center gap-2 px-3 pt-2">
            <div className="flex-1 border-l-2 pl-3 py-1 min-w-0" style={{ borderColor: 'var(--accent)' }}>
              <p className="text-xs font-semibold" style={{ color: 'var(--accent)' }}>
                {replyTo.senderId === 'me' ? 'Вы' : USERS.find(u => u.id === replyTo.senderId)?.name}
              </p>
              <p className="text-xs truncate" style={{ color: 'var(--text-secondary)' }}>{replyTo.text}</p>
            </div>
            <button
              onClick={() => setReplyTo(null)}
              className="w-6 h-6 rounded-full flex items-center justify-center text-sm flex-shrink-0"
              style={{ background: 'var(--input-bg)', color: 'var(--text-muted)' }}
            >
              ✕
            </button>
          </div>
        )}

        <div className="flex items-end gap-2 px-3 py-2">
          {/* Text input */}
          <div className="flex-1 flex items-end rounded-2xl px-4 py-2 min-h-[44px]"
            style={{ background: 'var(--input-bg)' }}>
            <textarea
              ref={inputRef}
              value={input}
              onChange={handleInputChange}
              onKeyDown={handleKeyDown}
              placeholder="Сообщение..."
              rows={1}
              className="flex-1 bg-transparent outline-none resize-none text-sm leading-relaxed"
              style={{
                color: 'var(--text-primary)',
                maxHeight: 120,
                overflowY: 'auto',
                paddingTop: 2,
              }}
            />
          </div>

          {/* Send button */}
          <button
            onClick={handleSend}
            disabled={!input.trim()}
            className="w-11 h-11 rounded-full flex items-center justify-center text-white transition-all active:scale-90 flex-shrink-0"
            style={{
              background: input.trim() ? 'var(--accent)' : 'var(--input-bg)',
              color: input.trim() ? 'white' : 'var(--text-muted)',
            }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
}
