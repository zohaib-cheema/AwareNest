export type User = { id: number; username: string };
export type Entry = { id: number; mood: number; note: string; created_at: string };
export type Day = { day: string; average: number | null; count: number };
export const moods = ['Low', 'Flat', 'Okay', 'Good', 'Great'];
export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}
export async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`/api${path}`, {
    ...options,
    credentials: 'same-origin',
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
  });
  if (response.status === 204) return undefined as T;
  if (!response.headers.get('Content-Type')?.includes('application/json')) {
    throw new ApiError(
      'The journal is temporarily unavailable. Please try again.',
      response.status,
    );
  }
  const result = await response.json();
  if (!response.ok) throw new ApiError(result.message || 'Please try again', response.status);
  return result;
}
