import { useState, useRef, useEffect } from 'react';
import { Message } from '../types';
import { USERS } from '../data/mockData';
import { formatTime } from '../utils/time';

const EMOJI_REACTIONS = ['👍', '❤️', '😂', '😮', '😢', '🔥', '🎉', '👏'];

interface Props {
  message: Message;
  isOwn: boolean;
  isGroup: boolean;
  onReact: (msgId: string, emoji: string) => void;
  onReply: (msg: Message) => void;
}

export default function MessageBubble({ message, isOwn, isGroup, onReact, onReply }: Props) {
  const [showActions, setShowActions] = useState(false);
  const [isTouchDevice] = useState(() => typeof window !== 'undefined' && ('ontouchstart' in window || navigator.maxTouchPoints > 0));
  const [longPressTimer, setLongPressTimer] = useState<ReturnType<typeof setTimeout> | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const hideTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const sender = USERS.find(u => u.id === message.senderId);
  const isSystem = message.type === 'system';

  // Close actions when clicking outside
  useEffect(() => {
    if (!showActions || !isTouchDevice) return;
    const handler = (e: MouseEvent | TouchEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setShowActions(false);
      }
    };
    document.addEventListener('mousedown', handler);
    document.addEventListener('touchstart', handler, { passive: true });
    return () => {
      document.removeEventListener('mousedown', handler);
      document.removeEventListener('touchstart', handler);
    };
  }, [showActions, isTouchDevice]);

  const showMenu = () => {
    if (hideTimer.current) clearTimeout(hideTimer.current);
    setShowActions(true);
  };

  const scheduleHide = () => {
    hideTimer.current = setTimeout(() => setShowActions(false), 150);
  };

  const cancelHide = () => {
    if (hideTimer.current) clearTimeout(hideTimer.current);
  };

  const handleLongPressStart = () => {
    const t = setTimeout(() => setShowActions(true), 500);
    setLongPressTimer(t);
  };

  const handleLongPressEnd = () => {
    if (longPressTimer) { clearTimeout(longPressTimer); setLongPressTimer(null); }
  };

  const handleReact = (emoji: string) => {
    onReact(message.id, emoji);
    setShowActions(false);
  };

  const handleReply = () => {
    onReply(message);
    setShowActions(false);
  };

  const myReactions = message.reactions.filter(r => r.users.includes('me')).map(r => r.emoji);

  if (isSystem) {
    return (
      <div className="flex justify-center py-1">
        <span className="text-xs px-3 py-1 rounded-full" style={{ background: 'var(--bubble-system)', color: 'var(--text-muted)' }}>
          {message.text}
        </span>
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      style={{ display: 'flex', gap: 8, justifyContent: isOwn ? 'flex-end' : 'flex-start', position: 'relative' }}
    >
      {/* Sender avatar (group, not own) */}
      {!isOwn && isGroup && (
        <div
          style={{
            width: 32, height: 32, borderRadius: '50%', display: 'flex', alignItems: 'center',
            justifyContent: 'center', fontSize: 16, flexShrink: 0, alignSelf: 'flex-end',
            marginBottom: 4, background: 'var(--input-bg)',
          }}
        >
          {sender?.avatar || '👤'}
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', maxWidth: '72%', alignItems: isOwn ? 'flex-end' : 'flex-start' }}>
        {/* Sender name (group) */}
        {!isOwn && isGroup && sender && (
          <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)', paddingLeft: 4, marginBottom: 2 }}>
            {sender.name}
          </span>
        )}

        {/* Wrapper for bubble + hover actions */}
        <div
          style={{ position: 'relative' }}
          onMouseEnter={() => !isTouchDevice && showMenu()}
          onMouseLeave={() => !isTouchDevice && scheduleHide()}
          onTouchStart={handleLongPressStart}
          onTouchEnd={handleLongPressEnd}
          onTouchMove={handleLongPressEnd}
          onContextMenu={e => { e.preventDefault(); setShowActions(true); }}
        >
          {/* Hover Actions Panel (desktop only) */}
          {!isTouchDevice && showActions && (
            <div
              onMouseEnter={cancelHide}
              onMouseLeave={scheduleHide}
              style={{
                position: 'absolute',
                bottom: '100%',
                [isOwn ? 'right' : 'left']: 0,
                marginBottom: 4,
                zIndex: 30,
                display: 'flex',
                flexDirection: 'column',
                gap: 4,
                alignItems: isOwn ? 'flex-end' : 'flex-start',
              }}
            >
              {/* Emoji row */}
              <div style={{
                display: 'flex', alignItems: 'center', gap: 2, padding: '6px 8px',
                borderRadius: 20, boxShadow: '0 8px 24px rgba(0,0,0,0.3)',
                background: 'var(--modal-bg)', border: '1px solid var(--border)',
              }}>
                {EMOJI_REACTIONS.map(e => (
                  <button
                    key={e}
                    onClick={() => handleReact(e)}
                    title={e}
                    style={{
                      width: 32, height: 32, borderRadius: 10, fontSize: 17,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      background: myReactions.includes(e) ? 'var(--accent-soft)' : 'transparent',
                      border: 'none', cursor: 'pointer', transition: 'transform 0.1s',
                    }}
                    onMouseEnter={e2 => (e2.currentTarget.style.transform = 'scale(1.3)')}
                    onMouseLeave={e2 => (e2.currentTarget.style.transform = 'scale(1)')}
                  >
                    {e}
                  </button>
                ))}
              </div>
              {/* Reply button */}
              <button
                onClick={handleReply}
                style={{
                  padding: '5px 12px', borderRadius: 12, fontSize: 12, fontWeight: 500,
                  display: 'flex', alignItems: 'center', gap: 4, cursor: 'pointer',
                  background: 'var(--modal-bg)', border: '1px solid var(--border)',
                  color: 'var(--text-secondary)', boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
                }}
              >
                ↩ Ответить
              </button>
            </div>
          )}

          {/* Message bubble */}
          <div
            style={{
              padding: '8px 14px',
              borderRadius: isOwn ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
              background: isOwn ? 'var(--bubble-out)' : 'var(--bubble-in)',
              color: isOwn ? 'var(--bubble-out-text)' : 'var(--text-primary)',
              fontSize: 14,
              lineHeight: 1.5,
              wordBreak: 'break-word',
              userSelect: 'text',
            }}
          >
            {message.text}
            {/* Time inline */}
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 2,
              marginLeft: 8, fontSize: 10, opacity: 0.6, float: 'right', marginTop: 2,
            }}>
              {message.edited && <span>изм.</span>}
              {formatTime(message.timestamp)}
              {isOwn && <span style={{ letterSpacing: -2 }}>✓✓</span>}
            </span>
          </div>
        </div>

        {/* Reactions display */}
        {message.reactions.length > 0 && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 4, paddingLeft: 4 }}>
            {message.reactions.map(r => (
              <button
                key={r.emoji}
                onClick={() => handleReact(r.emoji)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 4, padding: '2px 8px',
                  borderRadius: 12, fontSize: 12, cursor: 'pointer', transition: 'all 0.15s',
                  background: myReactions.includes(r.emoji) ? 'var(--accent-soft)' : 'var(--bubble-in)',
                  border: `1px solid ${myReactions.includes(r.emoji) ? 'var(--accent)' : 'var(--border)'}`,
                  color: 'var(--text-primary)',
                }}
              >
                <span>{r.emoji}</span>
                <span style={{ fontWeight: 600, color: myReactions.includes(r.emoji) ? 'var(--accent)' : 'var(--text-secondary)' }}>
                  {r.count}
                </span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Touch long-press action sheet */}
      {isTouchDevice && showActions && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 50, display: 'flex',
            alignItems: 'flex-end', background: 'rgba(0,0,0,0.45)',
          }}
          onClick={() => setShowActions(false)}
        >
          <div
            style={{
              width: '100%', padding: 16, borderRadius: '24px 24px 0 0',
              paddingBottom: 32, background: 'var(--modal-bg)',
            }}
            onClick={e => e.stopPropagation()}
          >
            {/* Message preview */}
            <div style={{
              padding: '8px 12px', borderRadius: 12, marginBottom: 12,
              background: isOwn ? 'var(--bubble-out)' : 'var(--bubble-in)',
              color: isOwn ? 'var(--bubble-out-text)' : 'var(--text-primary)',
              fontSize: 13, opacity: 0.8, maxHeight: 60, overflow: 'hidden',
            }}>
              {message.text.slice(0, 80)}{message.text.length > 80 ? '…' : ''}
            </div>

            {/* Emoji row */}
            <div style={{ display: 'flex', justifyContent: 'space-around', marginBottom: 16 }}>
              {EMOJI_REACTIONS.map(e => (
                <button
                  key={e}
                  onClick={() => handleReact(e)}
                  style={{
                    width: 40, height: 40, borderRadius: 12, fontSize: 22,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: myReactions.includes(e) ? 'var(--accent-soft)' : 'var(--input-bg)',
                    border: myReactions.includes(e) ? '1.5px solid var(--accent)' : '1.5px solid transparent',
                    cursor: 'pointer',
                  }}
                >
                  {e}
                </button>
              ))}
            </div>

            <div style={{ height: 1, background: 'var(--border)', marginBottom: 12 }} />

            {/* Action buttons */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <button
                onClick={handleReply}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                  borderRadius: 14, textAlign: 'left', background: 'var(--input-bg)',
                  color: 'var(--text-primary)', fontSize: 15, cursor: 'pointer', border: 'none', width: '100%',
                }}
              >
                <span>↩</span><span>Ответить</span>
              </button>
              <button
                onClick={() => { navigator.clipboard?.writeText(message.text); setShowActions(false); }}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                  borderRadius: 14, textAlign: 'left', background: 'var(--input-bg)',
                  color: 'var(--text-primary)', fontSize: 15, cursor: 'pointer', border: 'none', width: '100%',
                }}
              >
                <span>📋</span><span>Копировать</span>
              </button>
              <button
                onClick={() => setShowActions(false)}
                style={{
                  padding: '12px 16px', borderRadius: 14, fontWeight: 600, fontSize: 15,
                  color: 'var(--accent)', background: 'var(--accent-soft)', cursor: 'pointer',
                  border: 'none', width: '100%', marginTop: 4,
                }}
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
