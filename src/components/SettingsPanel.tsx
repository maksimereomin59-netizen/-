import { useState } from 'react';
import { User, Theme } from '../types';

const AVATARS = ['🧑', '👨', '👩', '🧔', '👧', '👦', '🧑‍💻', '🧑‍🎨', '🧑‍🚀', '🦸', '🧙', '🐱'];

interface Props {
  currentUser: User;
  theme: Theme;
  onClose: () => void;
  onUpdateUser: (user: User) => void;
  onChangeTheme: (theme: Theme) => void;
}

type SettingsSection = 'main' | 'profile' | 'appearance' | 'notifications' | 'privacy';

export default function SettingsPanel({ currentUser, theme, onClose, onUpdateUser, onChangeTheme }: Props) {
  const [section, setSection] = useState<SettingsSection>('main');
  const [editName, setEditName] = useState(currentUser.name);
  const [editUsername, setEditUsername] = useState(currentUser.username);
  const [editBio, setEditBio] = useState(currentUser.bio || '');
  const [editAvatar, setEditAvatar] = useState(currentUser.avatar);
  const [notifMessages, setNotifMessages] = useState(true);
  const [notifSound, setNotifSound] = useState(true);
  const [privacyPhone, setPrivacyPhone] = useState('contacts');
  const [saved, setSaved] = useState(false);

  const handleSaveProfile = () => {
    onUpdateUser({
      ...currentUser,
      name: editName.trim() || currentUser.name,
      username: editUsername.trim() || currentUser.username,
      bio: editBio.trim(),
      avatar: editAvatar,
    });
    setSaved(true);
    setTimeout(() => { setSaved(false); setSection('main'); }, 1200);
  };

  const themes: { id: Theme; label: string; icon: string; desc: string }[] = [
    { id: 'dark', label: 'Тёмная', icon: '🌙', desc: 'Тёмный фон, светлый текст' },
    { id: 'light', label: 'Светлая', icon: '☀️', desc: 'Светлый фон, тёмный текст' },
    { id: 'neutral', label: 'Нейтральная', icon: '🌫️', desc: 'Серые тона' },
  ];

  const menuItems: { id: SettingsSection; icon: string; label: string; desc: string }[] = [
    { id: 'profile', icon: '👤', label: 'Профиль', desc: 'Имя, аватар, биография' },
    { id: 'appearance', icon: '🎨', label: 'Оформление', desc: 'Тема, цвета' },
    { id: 'notifications', icon: '🔔', label: 'Уведомления', desc: 'Звуки, оповещения' },
    { id: 'privacy', icon: '🔒', label: 'Конфиденциальность', desc: 'Кто видит ваши данные' },
  ];

  const Toggle = ({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) => (
    <button
      onClick={() => onChange(!value)}
      className="relative w-12 h-6 rounded-full transition-colors flex-shrink-0"
      style={{ background: value ? 'var(--accent)' : 'var(--input-bg)' }}
    >
      <span
        className="absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-all"
        style={{ left: value ? '26px' : '2px' }}
      />
    </button>
  );

  return (
    <div className="h-full flex flex-col" style={{ background: 'var(--sidebar-bg)' }}>
      {/* Header */}
      <div className="flex items-center gap-3 px-4 py-4 border-b flex-shrink-0" style={{ borderColor: 'var(--border)' }}>
        {section !== 'main' ? (
          <button
            onClick={() => setSection('main')}
            className="w-9 h-9 rounded-xl flex items-center justify-center text-lg transition-all active:scale-90"
            style={{ color: 'var(--accent)', background: 'var(--accent-soft)' }}
          >
            ←
          </button>
        ) : (
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-xl flex items-center justify-center text-lg transition-all active:scale-90"
            style={{ color: 'var(--accent)', background: 'var(--accent-soft)' }}
          >
            ←
          </button>
        )}
        <h2 className="text-lg font-bold" style={{ color: 'var(--text-primary)' }}>
          {section === 'main' ? 'Настройки' :
           section === 'profile' ? 'Профиль' :
           section === 'appearance' ? 'Оформление' :
           section === 'notifications' ? 'Уведомления' : 'Конфиденциальность'}
        </h2>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* Main settings */}
        {section === 'main' && (
          <div className="space-y-2 p-3">
            {/* Profile card */}
            <button
              onClick={() => setSection('profile')}
              className="w-full flex items-center gap-4 p-4 rounded-2xl transition-all active:scale-95 text-left"
              style={{ background: 'var(--card-bg)', border: '1px solid var(--border)' }}
            >
              <div className="relative w-16 h-16 rounded-full flex items-center justify-center text-3xl flex-shrink-0"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}>
                {currentUser.avatar}
                <span className="absolute bottom-0 right-0 w-4 h-4 rounded-full border-2 flex items-center justify-center text-xs"
                  style={{ background: 'var(--accent)', borderColor: 'var(--card-bg)', color: 'white' }}>✏</span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-base font-bold truncate" style={{ color: 'var(--text-primary)' }}>{currentUser.name}</p>
                <p className="text-sm truncate" style={{ color: 'var(--text-secondary)' }}>@{currentUser.username}</p>
                {currentUser.bio && (
                  <p className="text-xs mt-1 truncate" style={{ color: 'var(--text-muted)' }}>{currentUser.bio}</p>
                )}
              </div>
              <span style={{ color: 'var(--text-muted)' }}>›</span>
            </button>

            {/* Menu items */}
            <div className="rounded-2xl overflow-hidden" style={{ background: 'var(--card-bg)', border: '1px solid var(--border)' }}>
              {menuItems.map((item, i) => (
                <button
                  key={item.id}
                  onClick={() => setSection(item.id)}
                  className="w-full flex items-center gap-3 px-4 py-3.5 transition-all active:scale-95 text-left"
                  style={{
                    borderBottom: i < menuItems.length - 1 ? '1px solid var(--border)' : 'none',
                  }}
                  onMouseEnter={e => (e.currentTarget.style.background = 'var(--accent-soft)')}
                  onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
                >
                  <span className="w-9 h-9 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                    style={{ background: 'var(--accent-soft)' }}>
                    {item.icon}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{item.label}</p>
                    <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{item.desc}</p>
                  </div>
                  <span style={{ color: 'var(--text-muted)' }}>›</span>
                </button>
              ))}
            </div>

            {/* App info */}
            <div className="rounded-2xl p-4 text-center space-y-1" style={{ background: 'var(--card-bg)', border: '1px solid var(--border)' }}>
              <div className="text-3xl">💬</div>
              <p className="text-sm font-bold" style={{ color: 'var(--text-primary)' }}>Connecta</p>
              <p className="text-xs" style={{ color: 'var(--text-muted)' }}>Версия 2.0 · Сделано с ❤️</p>
            </div>
          </div>
        )}

        {/* Profile settings */}
        {section === 'profile' && (
          <div className="p-4 space-y-4">
            {/* Avatar picker */}
            <div className="flex flex-col items-center gap-3">
              <div className="w-20 h-20 rounded-full flex items-center justify-center text-4xl"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}>
                {editAvatar}
              </div>
              <p className="text-xs" style={{ color: 'var(--text-muted)' }}>Выберите аватар</p>
              <div className="grid grid-cols-6 gap-2 w-full">
                {AVATARS.map(a => (
                  <button
                    key={a}
                    onClick={() => setEditAvatar(a)}
                    className="aspect-square rounded-xl text-2xl flex items-center justify-center transition-all active:scale-90"
                    style={{
                      background: editAvatar === a ? 'var(--accent-soft)' : 'var(--input-bg)',
                      border: editAvatar === a ? '2px solid var(--accent)' : '2px solid transparent',
                    }}
                  >
                    {a}
                  </button>
                ))}
              </div>
            </div>

            {/* Fields */}
            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold px-1 mb-1 block" style={{ color: 'var(--accent)' }}>Имя</label>
                <input
                  type="text"
                  value={editName}
                  onChange={e => setEditName(e.target.value)}
                  maxLength={32}
                  className="w-full px-4 py-3 rounded-xl text-sm outline-none"
                  style={{ background: 'var(--input-bg)', color: 'var(--text-primary)', border: '1px solid var(--border)' }}
                />
              </div>
              <div>
                <label className="text-xs font-semibold px-1 mb-1 block" style={{ color: 'var(--accent)' }}>Имя пользователя</label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-sm" style={{ color: 'var(--text-muted)' }}>@</span>
                  <input
                    type="text"
                    value={editUsername}
                    onChange={e => setEditUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                    maxLength={20}
                    className="w-full pl-8 pr-4 py-3 rounded-xl text-sm outline-none"
                    style={{ background: 'var(--input-bg)', color: 'var(--text-primary)', border: '1px solid var(--border)' }}
                  />
                </div>
              </div>
              <div>
                <label className="text-xs font-semibold px-1 mb-1 block" style={{ color: 'var(--accent)' }}>О себе</label>
                <textarea
                  value={editBio}
                  onChange={e => setEditBio(e.target.value)}
                  maxLength={100}
                  rows={3}
                  className="w-full px-4 py-3 rounded-xl text-sm outline-none resize-none"
                  style={{ background: 'var(--input-bg)', color: 'var(--text-primary)', border: '1px solid var(--border)' }}
                  placeholder="Расскажите о себе..."
                />
                <p className="text-xs text-right mt-0.5" style={{ color: 'var(--text-muted)' }}>{editBio.length}/100</p>
              </div>
            </div>

            <button
              onClick={handleSaveProfile}
              className="w-full py-3.5 rounded-xl text-white font-semibold transition-all active:scale-95"
              style={{ background: saved ? '#22c55e' : 'var(--accent)' }}
            >
              {saved ? '✓ Сохранено!' : 'Сохранить'}
            </button>
          </div>
        )}

        {/* Appearance */}
        {section === 'appearance' && (
          <div className="p-4 space-y-3">
            <p className="text-xs font-semibold px-1" style={{ color: 'var(--text-muted)' }}>ТЕМА</p>
            <div className="space-y-2">
              {themes.map(t => (
                <button
                  key={t.id}
                  onClick={() => onChangeTheme(t.id)}
                  className="w-full flex items-center gap-3 p-4 rounded-2xl transition-all active:scale-95 text-left"
                  style={{
                    background: 'var(--card-bg)',
                    border: theme === t.id ? '2px solid var(--accent)' : '2px solid var(--border)',
                  }}
                >
                  <span className="text-2xl">{t.icon}</span>
                  <div className="flex-1">
                    <p className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>{t.label}</p>
                    <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{t.desc}</p>
                  </div>
                  {theme === t.id && (
                    <span className="text-lg" style={{ color: 'var(--accent)' }}>✓</span>
                  )}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Notifications */}
        {section === 'notifications' && (
          <div className="p-4 space-y-3">
            <p className="text-xs font-semibold px-1" style={{ color: 'var(--text-muted)' }}>УВЕДОМЛЕНИЯ</p>
            <div className="rounded-2xl overflow-hidden" style={{ background: 'var(--card-bg)', border: '1px solid var(--border)' }}>
              {[
                { label: 'Уведомления о сообщениях', desc: 'Получать уведомления о новых сообщениях', value: notifMessages, onChange: setNotifMessages },
                { label: 'Звук', desc: 'Звуковые уведомления', value: notifSound, onChange: setNotifSound },
              ].map((item, i) => (
                <div key={item.label} className="flex items-center gap-3 px-4 py-3.5"
                  style={{ borderBottom: i < 1 ? '1px solid var(--border)' : 'none' }}>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{item.label}</p>
                    <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{item.desc}</p>
                  </div>
                  <Toggle value={item.value} onChange={item.onChange} />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Privacy */}
        {section === 'privacy' && (
          <div className="p-4 space-y-3">
            <p className="text-xs font-semibold px-1" style={{ color: 'var(--text-muted)' }}>КОНФИДЕНЦИАЛЬНОСТЬ</p>
            <div className="rounded-2xl overflow-hidden" style={{ background: 'var(--card-bg)', border: '1px solid var(--border)' }}>
              <div className="px-4 py-3.5">
                <p className="text-sm font-medium mb-2" style={{ color: 'var(--text-primary)' }}>Кто видит мой номер</p>
                {['all', 'contacts', 'nobody'].map((v, i) => (
                  <button
                    key={v}
                    onClick={() => setPrivacyPhone(v)}
                    className="flex items-center gap-3 w-full py-2 text-left"
                    style={{ borderBottom: i < 2 ? '1px solid var(--border)' : 'none' }}
                  >
                    <span className="w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0"
                      style={{ borderColor: privacyPhone === v ? 'var(--accent)' : 'var(--border)' }}>
                      {privacyPhone === v && <span className="w-2.5 h-2.5 rounded-full" style={{ background: 'var(--accent)' }} />}
                    </span>
                    <span className="text-sm" style={{ color: 'var(--text-primary)' }}>
                      {v === 'all' ? 'Все' : v === 'contacts' ? 'Только контакты' : 'Никто'}
                    </span>
                  </button>
                ))}
              </div>
            </div>
            <div className="rounded-2xl p-4" style={{ background: 'var(--card-bg)', border: '1px solid var(--border)' }}>
              <p className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>Статус активности</p>
              <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
                Когда вы отключите это, вы не сможете видеть статус других пользователей.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
