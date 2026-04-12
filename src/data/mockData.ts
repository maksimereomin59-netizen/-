import { User, Chat, Message } from '../types';

export const CURRENT_USER: User = {
  id: 'me',
  name: 'Вы',
  username: 'me',
  avatar: '🧑',
  status: 'online',
  bio: 'Привет! Я использую Connecta.',
};

export const USERS: User[] = [
  { id: 'u1', name: 'Алексей Смирнов', username: 'alex_smirnov', avatar: '👨', status: 'online', bio: 'Разработчик. Люблю код и кофе ☕' },
  { id: 'u2', name: 'Мария Иванова', username: 'maria_iv', avatar: '👩', status: 'online', bio: 'Дизайнер | Путешественница ✈️' },
  { id: 'u3', name: 'Дмитрий Козлов', username: 'dima_k', avatar: '🧔', status: 'away', lastSeen: '5 мин назад', bio: 'Просто Дима' },
  { id: 'u4', name: 'Анна Петрова', username: 'anna_p', avatar: '👧', status: 'offline', lastSeen: '1 час назад', bio: 'На связи 24/7 📱' },
  { id: 'u5', name: 'Команда Connecta', username: 'connecta_team', avatar: '⚡', status: 'online', bio: 'Официальный канал поддержки Connecta' },
];

const now = new Date();
const mins = (n: number) => new Date(now.getTime() - n * 60000);
const hours = (n: number) => new Date(now.getTime() - n * 3600000);
const days = (n: number) => new Date(now.getTime() - n * 86400000);

export const MESSAGES: Message[] = [
  // Chat c1 (Алексей)
  { id: 'm1', chatId: 'c1', senderId: 'u1', text: 'Привет! Как дела?', timestamp: hours(2), reactions: [], type: 'text' },
  { id: 'm2', chatId: 'c1', senderId: 'me', text: 'Всё отлично, спасибо! Работаю над новым проектом 🚀', timestamp: hours(2), reactions: [{ emoji: '👍', count: 1, users: ['u1'] }], type: 'text' },
  { id: 'm3', chatId: 'c1', senderId: 'u1', text: 'Это круто! Расскажи подробнее', timestamp: hours(1), reactions: [], type: 'text' },
  { id: 'm4', chatId: 'c1', senderId: 'me', text: 'Делаю мессенджер, очень интересно получается', timestamp: hours(1), reactions: [{ emoji: '🔥', count: 1, users: ['u1'] }], type: 'text' },
  { id: 'm5', chatId: 'c1', senderId: 'u1', text: 'Звучит здорово! Покажешь когда будет готово?', timestamp: mins(30), reactions: [], type: 'text' },
  { id: 'm6', chatId: 'c1', senderId: 'me', text: 'Конечно! Скоро покажу 😊', timestamp: mins(5), reactions: [], type: 'text' },

  // Chat c2 (Мария)
  { id: 'm7', chatId: 'c2', senderId: 'u2', text: 'Привет! Ты видел новый дизайн?', timestamp: hours(3), reactions: [], type: 'text' },
  { id: 'm8', chatId: 'c2', senderId: 'me', text: 'Да, выглядит отлично!', timestamp: hours(3), reactions: [{ emoji: '❤️', count: 1, users: ['u2'] }], type: 'text' },
  { id: 'm9', chatId: 'c2', senderId: 'u2', text: 'Спасибо! Старалась 🎨', timestamp: mins(120), reactions: [], type: 'text' },

  // Chat c3 (Дмитрий)
  { id: 'm10', chatId: 'c3', senderId: 'u3', text: 'Эй, ты свободен сегодня вечером?', timestamp: hours(5), reactions: [], type: 'text' },
  { id: 'm11', chatId: 'c3', senderId: 'me', text: 'Думаю да, а что планируешь?', timestamp: hours(4), reactions: [], type: 'text' },
  { id: 'm12', chatId: 'c3', senderId: 'u3', text: 'Может встретимся, поговорим о делах', timestamp: hours(4), reactions: [], type: 'text' },

  // Chat c4 (Анна)
  { id: 'm13', chatId: 'c4', senderId: 'u4', text: 'Доброе утро! 🌅', timestamp: days(1), reactions: [{ emoji: '☀️', count: 1, users: ['me'] }], type: 'text' },
  { id: 'm14', chatId: 'c4', senderId: 'me', text: 'Доброе! Как ты?', timestamp: days(1), reactions: [], type: 'text' },
  { id: 'm15', chatId: 'c4', senderId: 'u4', text: 'Отлично, спасибо! Увидимся завтра?', timestamp: days(1), reactions: [], type: 'text' },

  // Chat c5 (Группа)
  { id: 'm16', chatId: 'c5', senderId: 'u1', text: 'Всем привет в нашей группе! 👋', timestamp: hours(6), reactions: [{ emoji: '👋', count: 3, users: ['me', 'u2', 'u4'] }], type: 'text' },
  { id: 'm17', chatId: 'c5', senderId: 'u2', text: 'Привет-привет!', timestamp: hours(5), reactions: [], type: 'text' },
  { id: 'm18', chatId: 'c5', senderId: 'me', text: 'Привет всем! Рад быть здесь 😊', timestamp: hours(4), reactions: [{ emoji: '❤️', count: 2, users: ['u1', 'u2'] }], type: 'text' },
  { id: 'm19', chatId: 'c5', senderId: 'u3', text: 'Хорошая группа получилась!', timestamp: hours(2), reactions: [], type: 'text' },
  { id: 'm20', chatId: 'c5', senderId: 'u4', text: 'Да, давно хотела такую создать 🎉', timestamp: mins(45), reactions: [], type: 'text' },

  // Chat c6 (Команда Connecta)
  { id: 'm21', chatId: 'c6', senderId: 'u5', text: '👋 Добро пожаловать в Connecta!', timestamp: days(7), reactions: [], type: 'system' },
  { id: 'm22', chatId: 'c6', senderId: 'u5', text: 'Это официальный канал нашей команды. Здесь вы найдёте обновления, советы и поддержку.', timestamp: days(7), reactions: [], type: 'text' },
  { id: 'm23', chatId: 'c6', senderId: 'u5', text: '⚡ Версия 2.0 уже доступна! Теперь с поддержкой тёмной темы и реакциями на сообщения.', timestamp: days(3), reactions: [{ emoji: '🔥', count: 5, users: ['me', 'u1', 'u2', 'u3', 'u4'] }], type: 'text' },
  { id: 'm24', chatId: 'c6', senderId: 'u5', text: 'Спасибо, что используете Connecta! Ваши отзывы помогают нам становиться лучше 💜', timestamp: days(1), reactions: [{ emoji: '❤️', count: 3, users: ['me', 'u1', 'u2'] }], type: 'text' },
];

export const CHATS: Chat[] = [
  {
    id: 'c6',
    type: 'private',
    name: 'Команда Connecta',
    avatar: '⚡',
    members: ['me', 'u5'],
    lastMessage: MESSAGES.find(m => m.id === 'm24'),
    unread: 0,
    pinned: true,
  },
  {
    id: 'c1',
    type: 'private',
    name: 'Алексей Смирнов',
    avatar: '👨',
    members: ['me', 'u1'],
    lastMessage: MESSAGES.find(m => m.id === 'm6'),
    unread: 2,
  },
  {
    id: 'c5',
    type: 'group',
    name: 'Наша группа 🎉',
    avatar: '👥',
    members: ['me', 'u1', 'u2', 'u3', 'u4'],
    lastMessage: MESSAGES.find(m => m.id === 'm20'),
    unread: 1,
  },
  {
    id: 'c2',
    type: 'private',
    name: 'Мария Иванова',
    avatar: '👩',
    members: ['me', 'u2'],
    lastMessage: MESSAGES.find(m => m.id === 'm9'),
    unread: 0,
  },
  {
    id: 'c3',
    type: 'private',
    name: 'Дмитрий Козлов',
    avatar: '🧔',
    members: ['me', 'u3'],
    lastMessage: MESSAGES.find(m => m.id === 'm12'),
    unread: 0,
  },
  {
    id: 'c4',
    type: 'private',
    name: 'Анна Петрова',
    avatar: '👧',
    members: ['me', 'u4'],
    lastMessage: MESSAGES.find(m => m.id === 'm15'),
    unread: 0,
  },
];
