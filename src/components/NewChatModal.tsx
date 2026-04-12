import { useState } from 'react';
import { USERS } from '../data/mockData';
import { Chat } from '../types';

interface Props {
  existingChats: Chat[];
  onClose: () => void;
  onSelectChat: (chatId: string) => void;
  onCreateChat: (chat: Chat) => void;
}

export default function NewChatModal({ existingChats, onClose, onSelectChat, onCreateChat }: Props) {
  const [search, setSearch] = useState('');

  const filtered = USERS.filter(u =>
    u.name.toLowerCase().includes(search.toLowerCase()) ||
    u.username.toLowerCase().includes(search.toLowerCase())
  );

  const handleSelect = (userId: string) => {
    // Check if chat already exists
    const existing = existingChats.find(c =>
      c.type === 'private' && c.members.includes(userId) && c.members.includes('me')
    );
    if (existing) {
      onSelectChat(existing.id);
      onClose();
      return;
    }

    const user = USERS.find(u => u.id === userId)!;
    const newChat: Chat = {
      id: `c_new_${userId}_${Date.now()}`,
      type: 'private',
      name: user.name,
      avatar: user.avatar,
      members: ['me', userId],
      unread: 0,
    };
    onCreateChat(newChat);
    onSelectChat(newChat.id);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center"
      style={{ background: 'rgba(0,0,0,0.5)' }}
      onClick={onClose}>
      <div
        className="w-full md:max-w-sm md:mx-4 rounded-t-3xl md:rounded-3xl overflow-hidden"
        style={{ background: 'var(--modal-bg)', maxHeight: '80vh' }}
        onClick={e => e.stopPropagation()}
      >
        <div className="p-4 border-b" style={{ borderColor: 'var(--border)' }}>
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-base font-bold" style={{ color: 'var(--text-primary)' }}>Новый чат</h3>
            <button onClick={onClose} className="text-xl" style={{ color: 'var(--text-muted)' }}>✕</button>
          </div>
          <div className="flex items-center gap-2 px-3 rounded-xl" style={{ background: 'var(--input-bg)' }}>
            <span style={{ color: 'var(--text-muted)' }}>🔍</span>
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Поиск пользователей..."
              autoFocus
              className="flex-1 py-2.5 text-sm bg-transparent outline-none"
              style={{ color: 'var(--text-primary)' }}
            />
          </div>
        </div>
        <div className="overflow-y-auto" style={{ maxHeight: '50vh' }}>
          {filtered.map(user => (
            <button
              key={user.id}
              onClick={() => handleSelect(user.id)}
              className="w-full flex items-center gap-3 px-4 py-3 text-left transition-all active:scale-95"
              style={{ borderBottom: '1px solid var(--border)' }}
              onMouseEnter={e => (e.currentTarget.style.background = 'var(--accent-soft)')}
              onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
            >
              <div className="relative w-11 h-11 rounded-full flex items-center justify-center text-2xl flex-shrink-0"
                style={{ background: 'var(--input-bg)' }}>
                {user.avatar}
                {user.status === 'online' && (
                  <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full border-2"
                    style={{ background: '#22c55e', borderColor: 'var(--modal-bg)' }} />
                )}
              </div>
              <div>
                <p className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>{user.name}</p>
                <p className="text-xs" style={{ color: 'var(--text-muted)' }}>@{user.username}</p>
              </div>
            </button>
          ))}
          {filtered.length === 0 && (
            <div className="flex flex-col items-center py-8 space-y-2">
              <span className="text-3xl">👤</span>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Пользователи не найдены</p>
            </div>
          )}
        </div>
        <div className="p-4">
          <button onClick={onClose} className="w-full py-3 rounded-xl font-semibold text-sm"
            style={{ background: 'var(--input-bg)', color: 'var(--text-secondary)' }}>
            Отмена
          </button>
        </div>
      </div>
    </div>
  );
}
