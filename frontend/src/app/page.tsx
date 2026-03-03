/**
 * Where Should We Eat? - Home Page
 * TODO: Add "Create Room" and "Join Room" buttons/forms
 * TODO: Create room page (host flow)
 * TODO: Join room page (participant flow - enter code + display name)
 * TODO: Room page with options list, add option form, voting UI
 * TODO: Integrate WebSocket (socket.io-client) for real-time updates
 * TODO: Add countdown timer component
 * TODO: Add results/winner display
 * TODO: Add restart session for host
 */
export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-zinc-50 p-8 dark:bg-black">
      <main className="flex max-w-md flex-col items-center gap-8 text-center">
        <h1 className="text-4xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50">
          Where Should We Eat?
        </h1>
        <p className="text-lg text-zinc-600 dark:text-zinc-400">
          Decide on a restaurant with your group in under 2 minutes.
        </p>
        <div className="flex flex-col gap-4 sm:flex-row">
          {/* TODO: Wire up Create Room */}
          <button className="rounded-full bg-zinc-900 px-6 py-3 font-medium text-white transition hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200">
            Create Room
          </button>
          {/* TODO: Wire up Join Room */}
          <button className="rounded-full border border-zinc-300 px-6 py-3 font-medium transition hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800">
            Join Room
          </button>
        </div>
      </main>
    </div>
  );
}
