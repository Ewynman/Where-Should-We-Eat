/**
 * Where Should We Eat? - API Client
 * TODO: Add fetch wrapper for REST endpoints (create room, join room, add option, vote)
 * TODO: Add WebSocket connection helper (socket.io-client)
 * TODO: Use NEXT_PUBLIC_API_URL env var (default http://localhost:8000)
 */
export const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";
