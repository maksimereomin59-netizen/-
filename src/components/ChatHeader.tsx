import { Chat, User } from '../types';
import { USERS } from '../data/mockData';

interface Props {
  chat: Chat;
  currentUser: User;
  onBack: () => void;
  onOpenInfo: () => void;
}

export default function ChatHeader({ chat, onBack, onOpenInfo }: Props) {
  const getOtherUser = () => {
    if (chat.type === 'group') return null;
    const otherId = chat.members.find(m => m !== 'me');
    return USERS.find(u => u.id === otherId) || null;
  };

  const otherUser = getOtherUser();
  const statusText =
    chat.type === 'group'
      ? `${chat.members.length} участников`
      : otherUser?.status === 'online'
      ? 'в сети'
      : otherUser?.status === 'away'
      ? 'отходил(а)'
      : otherUser?.lastSeen || 'не в сети';

  const statusColor =
    otherUser?.status === 'online' ? '#22c55e' : otherUser?.status === 'away' ? '#f59e0b' : 'var(--text-muted)';

  return (
    <div
      className="flex items-center gap-3 px-3 py-2 flex-shrink-0 border-b"
      style={{ background: 'var(--header-bg)', borderColor: 'var(--border)', minHeight: 56 }}
    >
      {/* Back button (mobile) */}
      <button
        onClick={onBack}
        className="md:hidden w-9 h-9 flex items-center justify-center rounded-xl transition-all active:scale-90 text-lg flex-shrink-0"
        style={{ color: 'var(--accent)', background: 'var(--accent-soft)' }}
      >
        ←
      </button>

      {/* Avatar + info */}
      <button onClick={onOpenInfo} className="flex items-center gap-3 flex-1 min-w-0 text-left active:opacity-70 transition-opacity">
        <div className="relative w-10 h-10 rounded-full flex items-center justify-center text-xl flex-shrink-0"
          style={{ background: 'var(--input-bg)' }}>
          {chat.avatar}
          {otherUser?.status === 'online' && (
            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full border-2"
              style={{ background: '#22c55e', borderColor: 'var(--header-bg)' }} />
          )}
        </div>
        <div className="min-w-0">
          <p className="font-semibold text-sm truncate" style={{ color: 'var(--text-primary)' }}>{chat.name}</p>
          <p className="text-xs" style={{ color: statusColor }}>{statusText}</p>
        </div>
      </button>

      {/* Actions */}
      <div className="flex items-center gap-1 flex-shrink-0">
        <button
          className="w-9 h-9 flex items-center justify-center rounded-xl transition-all active:scale-90 text-base"
          style={{ color: 'var(--text-secondary)', background: 'transparent' }}
          onMouseEnter={e => (e.currentTarget.style.background = 'var(--accent-soft)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
          title="Поиск"
        >
          🔍
        </button>
        <button
          onClick={onOpenInfo}
          className="w-9 h-9 flex items-center justify-center rounded-xl transition-all active:scale-90 text-base"
          style={{ color: 'var(--text-secondary)', background: 'transparent' }}
          onMouseEnter={e => (e.currentTarget.style.background = 'var(--accent-soft)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
          title="Информация"
        >
          ⋮
        </button>
      </div>
    </div>
  );
}
