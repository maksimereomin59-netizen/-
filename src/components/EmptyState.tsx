export default function EmptyState() {
  return (
    <div
      className="hidden md:flex flex-col items-center justify-center h-full"
      style={{ background: 'var(--chat-bg)' }}
    >
      <div className="text-center space-y-4 p-8 max-w-xs">
        <div className="text-6xl">💬</div>
        <div>
          <h2 className="text-xl font-bold mb-1" style={{ color: 'var(--text-primary)' }}>
            Добро пожаловать!
          </h2>
          <p className="text-sm" style={{ color: 'var(--text-muted)' }}>
            Выберите чат слева, чтобы начать общение
          </p>
        </div>
        <div className="flex flex-col gap-2 pt-2">
          {[
            { icon: '👈', text: 'Выберите чат из списка' },
            { icon: '✉️', text: 'Или напишите новое сообщение' },
            { icon: '⚡', text: 'Общайтесь мгновенно' },
          ].map(tip => (
            <div key={tip.text} className="flex items-center gap-3 px-4 py-2.5 rounded-xl text-left"
              style={{ background: 'var(--bubble-system)' }}>
              <span className="text-lg flex-shrink-0">{tip.icon}</span>
              <span className="text-sm" style={{ color: 'var(--text-secondary)' }}>{tip.text}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
