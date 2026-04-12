import { useState } from 'react';
import { User } from '../types';
import { CURRENT_USER } from '../data/mockData';

interface Props {
  onComplete: (user: User) => void;
}

const AVATARS = ['🧑', '👨', '👩', '🧔', '👧', '👦', '🧑‍💻', '🧑‍🎨', '🧑‍🚀', '🦸', '🧙', '🐱'];

export default function WelcomeScreen({ onComplete }: Props) {
  const [step, setStep] = useState<'welcome' | 'name' | 'avatar'>('welcome');
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [avatar, setAvatar] = useState('🧑');
  const [nameError, setNameError] = useState('');

  const handleNameNext = () => {
    if (name.trim().length < 2) {
      setNameError('Имя должно содержать минимум 2 символа');
      return;
    }
    if (!username.trim()) {
      setUsername(name.trim().toLowerCase().replace(/\s+/g, '_'));
    }
    setNameError('');
    setStep('avatar');
  };

  const handleComplete = () => {
    const user: User = {
      ...CURRENT_USER,
      name: name.trim(),
      username: username.trim() || name.trim().toLowerCase().replace(/\s+/g, '_'),
      avatar,
    };
    onComplete(user);
  };

  return (
    <div
      className="fixed inset-0 flex items-center justify-center"
      style={{ background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)' }}
    >
      {/* Background blobs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full opacity-20" style={{ background: 'radial-gradient(circle, #6366f1, transparent)' }} />
        <div className="absolute -bottom-32 -right-32 w-96 h-96 rounded-full opacity-20" style={{ background: 'radial-gradient(circle, #8b5cf6, transparent)' }} />
      </div>

      <div className="relative w-full max-w-sm mx-4">
        {/* Welcome step */}
        {step === 'welcome' && (
          <div className="text-center space-y-8">
            {/* Logo */}
            <div className="flex flex-col items-center space-y-4">
              <div className="w-24 h-24 rounded-3xl flex items-center justify-center text-5xl shadow-2xl"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}>
                💬
              </div>
              <div>
                <h1 className="text-4xl font-bold text-white tracking-tight">Connecta</h1>
                <p className="text-white/60 mt-1 text-base">Быстро. Просто. Надёжно.</p>
              </div>
            </div>

            {/* Features */}
            <div className="space-y-3 text-left">
              {[
                { icon: '🔒', title: 'Приватность', desc: 'Ваши сообщения защищены' },
                { icon: '⚡', title: 'Молниеносно', desc: 'Мгновенная доставка сообщений' },
                { icon: '📱', title: 'Везде', desc: 'Работает на любом устройстве' },
              ].map(f => (
                <div key={f.title} className="flex items-center gap-4 rounded-2xl p-3"
                  style={{ background: 'rgba(255,255,255,0.07)' }}>
                  <span className="text-2xl w-10 h-10 flex items-center justify-center rounded-xl"
                    style={{ background: 'rgba(99,102,241,0.2)' }}>{f.icon}</span>
                  <div>
                    <div className="text-white font-semibold text-sm">{f.title}</div>
                    <div className="text-white/50 text-xs">{f.desc}</div>
                  </div>
                </div>
              ))}
            </div>

            <button
              onClick={() => setStep('name')}
              className="w-full py-4 rounded-2xl text-white font-semibold text-base active:scale-95 transition-transform"
              style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}
            >
              Начать →
            </button>
            <p className="text-white/30 text-xs">Нажимая кнопку, вы соглашаетесь с условиями использования</p>
          </div>
        )}

        {/* Name step */}
        {step === 'name' && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl mx-auto mb-4"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}>
                👤
              </div>
              <h2 className="text-2xl font-bold text-white">Ваше имя</h2>
              <p className="text-white/50 text-sm">Как вас будут видеть другие пользователи</p>
            </div>

            <div className="space-y-3">
              <div>
                <input
                  type="text"
                  value={name}
                  onChange={e => { setName(e.target.value); setNameError(''); }}
                  onKeyDown={e => e.key === 'Enter' && handleNameNext()}
                  placeholder="Ваше имя"
                  maxLength={32}
                  autoFocus
                  className="w-full px-4 py-3.5 rounded-2xl text-white placeholder-white/30 outline-none text-base"
                  style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.15)' }}
                />
                {nameError && <p className="text-red-400 text-xs mt-1 px-1">{nameError}</p>}
              </div>
              <input
                type="text"
                value={username}
                onChange={e => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                placeholder="Имя пользователя (необязательно)"
                maxLength={20}
                className="w-full px-4 py-3.5 rounded-2xl text-white placeholder-white/30 outline-none text-base"
                style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.15)' }}
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setStep('welcome')}
                className="flex-1 py-4 rounded-2xl text-white/70 font-semibold text-base active:scale-95 transition-transform"
                style={{ background: 'rgba(255,255,255,0.08)' }}
              >
                ← Назад
              </button>
              <button
                onClick={handleNameNext}
                className="flex-1 py-4 rounded-2xl text-white font-semibold text-base active:scale-95 transition-transform"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}
              >
                Далее →
              </button>
            </div>
          </div>
        )}

        {/* Avatar step */}
        {step === 'avatar' && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <div className="w-20 h-20 rounded-full flex items-center justify-center text-4xl mx-auto mb-4 ring-4"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)', boxShadow: '0 0 0 4px rgba(99,102,241,0.3)' }}>
                {avatar}
              </div>
              <h2 className="text-2xl font-bold text-white">Выберите аватар</h2>
              <p className="text-white/50 text-sm">Можно изменить позже в настройках</p>
            </div>

            <div className="grid grid-cols-4 gap-3">
              {AVATARS.map(a => (
                <button
                  key={a}
                  onClick={() => setAvatar(a)}
                  className="aspect-square rounded-2xl text-3xl flex items-center justify-center transition-all active:scale-90"
                  style={{
                    background: avatar === a ? 'linear-gradient(135deg, #6366f1, #8b5cf6)' : 'rgba(255,255,255,0.08)',
                    transform: avatar === a ? 'scale(1.05)' : undefined,
                    boxShadow: avatar === a ? '0 0 20px rgba(99,102,241,0.5)' : undefined,
                  }}
                >
                  {a}
                </button>
              ))}
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setStep('name')}
                className="flex-1 py-4 rounded-2xl text-white/70 font-semibold text-base active:scale-95 transition-transform"
                style={{ background: 'rgba(255,255,255,0.08)' }}
              >
                ← Назад
              </button>
              <button
                onClick={handleComplete}
                className="flex-1 py-4 rounded-2xl text-white font-semibold text-base active:scale-95 transition-transform"
                style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)' }}
              >
                Готово ✓
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
