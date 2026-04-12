export interface User {
  id: string;
  name: string;
  username: string;
  avatar: string;
  status: 'online' | 'offline' | 'away';
  lastSeen?: string;
  bio?: string;
}

export interface Reaction {
  emoji: string;
  count: number;
  users: string[];
}

export interface Message {
  id: string;
  chatId: string;
  senderId: string;
  text: string;
  timestamp: Date;
  reactions: Reaction[];
  replyTo?: string;
  edited?: boolean;
  type: 'text' | 'system';
}

export interface Chat {
  id: string;
  type: 'private' | 'group';
  name: string;
  avatar: string;
  members: string[];
  lastMessage?: Message;
  unread: number;
  pinned?: boolean;
  muted?: boolean;
}

export type Theme = 'dark' | 'light' | 'neutral';
export type ActiveView = 'chats' | 'settings';
