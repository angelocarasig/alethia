export class HttpError extends Error {
  constructor(
    message: string,
    public status: number,
    public statusText: string,
    public response?: unknown,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}
