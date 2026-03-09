(globalThis.TURBOPACK || (globalThis.TURBOPACK = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/src/lib/api.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "API_BASE",
    ()=>API_BASE,
    "addOption",
    ()=>addOption,
    "createRoom",
    ()=>createRoom,
    "getRoom",
    ()=>getRoom,
    "joinRoom",
    ()=>joinRoom,
    "restartRoom",
    ()=>restartRoom,
    "startTimer",
    ()=>startTimer,
    "vote",
    ()=>vote
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = /*#__PURE__*/ __turbopack_context__.i("[project]/node_modules/next/dist/build/polyfills/process.js [app-client] (ecmascript)");
const API_BASE = __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"].env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";
async function fetchApi(path, options) {
    const res = await fetch(`${API_BASE}${path}`, {
        ...options,
        headers: {
            "Content-Type": "application/json",
            ...options?.headers
        }
    });
    if (!res.ok) {
        const err = await res.json().catch(()=>({
                detail: res.statusText
            }));
        throw new Error(err.detail ?? "Request failed");
    }
    return res.json();
}
const USE_MOCK = __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"].env.NEXT_PUBLIC_USE_MOCK === "true";
async function tryApi(fn, mockFn) {
    if (USE_MOCK) return mockFn();
    try {
        return await fn();
    } catch  {
        return mockFn();
    }
}
async function createRoom(name) {
    return tryApi(()=>fetchApi("/api/rooms", {
            method: "POST",
            body: JSON.stringify({
                name
            })
        }), async ()=>{
        const { mockCreateRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        return mockCreateRoom(name);
    });
}
async function joinRoom(code, name) {
    return tryApi(()=>fetchApi("/api/rooms/join", {
            method: "POST",
            body: JSON.stringify({
                code: code.toUpperCase(),
                name
            })
        }), async ()=>{
        const { mockJoinRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        return mockJoinRoom(code, name);
    });
}
async function addOption(roomCode, optionName, userId) {
    return tryApi(()=>fetchApi(`/api/rooms/${roomCode}/options`, {
            method: "POST",
            body: JSON.stringify({
                name: optionName,
                userId
            })
        }), async ()=>{
        const { mockAddOption } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        return mockAddOption(roomCode, optionName);
    });
}
async function vote(roomCode, optionId, userId) {
    return tryApi(()=>fetchApi(`/api/rooms/${roomCode}/vote`, {
            method: "POST",
            body: JSON.stringify({
                optionId,
                userId
            })
        }), async ()=>{
        const { mockVote } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        return mockVote(roomCode, optionId, userId);
    });
}
async function startTimer(roomCode, params) {
    const { userId, durationSeconds = 60, latitude, longitude } = params;
    return tryApi(()=>fetchApi(`/api/rooms/${roomCode}/start`, {
            method: "POST",
            body: JSON.stringify({
                userId,
                durationSeconds,
                latitude,
                longitude
            })
        }), async ()=>{
        const { mockStartTimer } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        return mockStartTimer(roomCode, durationSeconds, latitude, longitude);
    });
}
async function restartRoom(roomCode, userId) {
    return tryApi(()=>fetchApi(`/api/rooms/${roomCode}/restart`, {
            method: "POST",
            body: JSON.stringify({
                userId
            })
        }), async ()=>{
        const { mockRestartRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        return mockRestartRoom(roomCode);
    });
}
async function getRoom(roomCode) {
    return tryApi(()=>fetchApi(`/api/rooms/${roomCode}`), async ()=>{
        const { mockGetRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-client] (ecmascript, async loader)");
        const room = mockGetRoom(roomCode);
        if (!room) throw new Error("Room not found");
        return room;
    });
}
;
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/lib/socket.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "connectSocket",
    ()=>connectSocket,
    "disconnectSocket",
    ()=>disconnectSocket,
    "getSocket",
    ()=>getSocket,
    "useRoomUpdates",
    ()=>useRoomUpdates
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = /*#__PURE__*/ __turbopack_context__.i("[project]/node_modules/next/dist/build/polyfills/process.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$socket$2e$io$2d$client$2f$build$2f$esm$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__$3c$locals$3e$__ = __turbopack_context__.i("[project]/node_modules/socket.io-client/build/esm/index.js [app-client] (ecmascript) <locals>");
var _s = __turbopack_context__.k.signature();
"use client";
;
;
const WS_BASE = __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"].env.NEXT_PUBLIC_WS_URL ?? __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"].env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";
let socket = null;
function getSocket() {
    return socket;
}
function connectSocket() {
    if (socket?.connected) return socket;
    socket = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$socket$2e$io$2d$client$2f$build$2f$esm$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__$3c$locals$3e$__["io"])(WS_BASE, {
        transports: [
            "websocket",
            "polling"
        ],
        reconnection: true,
        reconnectionAttempts: 5
    });
    return socket;
}
function disconnectSocket() {
    if (socket) {
        socket.disconnect();
        socket = null;
    }
}
function useRoomUpdates(roomCode, onUpdate) {
    _s();
    const [connected, setConnected] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const onUpdateRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(onUpdate);
    onUpdateRef.current = onUpdate;
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "useRoomUpdates.useEffect": ()=>{
            if (!roomCode) return;
            const s = connectSocket();
            s.emit("join_room", roomCode);
            const handleConnect = {
                "useRoomUpdates.useEffect.handleConnect": ()=>setConnected(true)
            }["useRoomUpdates.useEffect.handleConnect"];
            const handleDisconnect = {
                "useRoomUpdates.useEffect.handleDisconnect": ()=>setConnected(false)
            }["useRoomUpdates.useEffect.handleDisconnect"];
            const handleRoomUpdate = {
                "useRoomUpdates.useEffect.handleRoomUpdate": (payload)=>{
                    onUpdateRef.current(payload);
                }
            }["useRoomUpdates.useEffect.handleRoomUpdate"];
            s.on("connect", handleConnect);
            s.on("disconnect", handleDisconnect);
            s.on("room_update", handleRoomUpdate);
            if (s.connected) setConnected(true);
            return ({
                "useRoomUpdates.useEffect": ()=>{
                    s.off("connect", handleConnect);
                    s.off("disconnect", handleDisconnect);
                    s.off("room_update", handleRoomUpdate);
                    s.emit("leave_room", roomCode);
                }
            })["useRoomUpdates.useEffect"];
        }
    }["useRoomUpdates.useEffect"], [
        roomCode
    ]);
    return {
        connected
    };
}
_s(useRoomUpdates, "j4NIPYUFQKxCpE3ln5XpiVsH4aI=");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/components/CountdownTimer.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "CountdownTimer",
    ()=>CountdownTimer
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
"use client";
;
function CountdownTimer({ endTime, onComplete, size = "lg" }) {
    _s();
    const [secondsLeft, setSecondsLeft] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "CountdownTimer.useEffect": ()=>{
            if (!endTime) return;
            const update = {
                "CountdownTimer.useEffect.update": ()=>{
                    const end = new Date(endTime).getTime();
                    const now = Date.now();
                    const diff = Math.max(0, Math.ceil((end - now) / 1000));
                    setSecondsLeft(diff);
                    if (diff === 0) onComplete?.();
                }
            }["CountdownTimer.useEffect.update"];
            update();
            const interval = setInterval(update, 1000);
            return ({
                "CountdownTimer.useEffect": ()=>clearInterval(interval)
            })["CountdownTimer.useEffect"];
        }
    }["CountdownTimer.useEffect"], [
        endTime,
        onComplete
    ]);
    if (secondsLeft === null) return null;
    const isCritical = secondsLeft <= 10;
    const sizeClass = size === "sm" ? "text-2xl w-16 h-16" : size === "md" ? "text-4xl w-24 h-24" : "text-6xl md:text-8xl w-32 h-32 md:w-40 md:h-40";
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: `flex items-center justify-center rounded-2xl bg-[#1e1b4b] text-white font-bold ${sizeClass} ${isCritical ? "timer-critical bg-[#dc2626]" : ""}`,
        children: secondsLeft
    }, void 0, false, {
        fileName: "[project]/src/components/CountdownTimer.tsx",
        lineNumber: 41,
        columnNumber: 5
    }, this);
}
_s(CountdownTimer, "jk80L/9Vmtx8MKA9ehJ20qfNvlE=");
_c = CountdownTimer;
var _c;
__turbopack_context__.k.register(_c, "CountdownTimer");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/lib/colors.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "OPTION_COLORS",
    ()=>OPTION_COLORS
]);
const OPTION_COLORS = [
    {
        bg: "bg-[#1e40af]",
        hover: "hover:bg-[#1e3a8a]",
        text: "text-white",
        border: "border-[#1e40af]"
    },
    {
        bg: "bg-[#dc2626]",
        hover: "hover:bg-[#b91c1c]",
        text: "text-white",
        border: "border-[#dc2626]"
    },
    {
        bg: "bg-[#059669]",
        hover: "hover:bg-[#047857]",
        text: "text-white",
        border: "border-[#059669]"
    },
    {
        bg: "bg-[#d97706]",
        hover: "hover:bg-[#b45309]",
        text: "text-white",
        border: "border-[#d97706]"
    }
];
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/components/OptionButton.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "OptionButton",
    ()=>OptionButton
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$colors$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/colors.ts [app-client] (ecmascript)");
"use client";
;
;
function OptionButton({ name, voteCount, address, colorIndex, disabled, selected, onClick }) {
    const color = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$colors$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["OPTION_COLORS"][colorIndex % __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$colors$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["OPTION_COLORS"].length];
    const isVoting = !disabled && onClick;
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
        type: "button",
        onClick: onClick,
        disabled: disabled,
        className: `
        option-hover w-full rounded-2xl border-4 px-6 py-5 text-left font-bold transition-all
        ${color.bg} ${color.hover} ${color.text} ${color.border}
        ${selected ? "ring-4 ring-white ring-offset-4 ring-offset-[#1e1b4b]" : ""}
        ${isVoting ? "cursor-pointer" : "cursor-default"}
        ${disabled ? "opacity-90" : ""}
      `,
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "flex flex-col gap-1",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "flex items-center justify-between gap-4",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                            className: "text-lg font-bold md:text-xl",
                            children: name
                        }, void 0, false, {
                            fileName: "[project]/src/components/OptionButton.tsx",
                            lineNumber: 42,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                            className: "rounded-full bg-white/25 px-3 py-1 text-sm",
                            children: [
                                voteCount,
                                " ",
                                voteCount === 1 ? "vote" : "votes"
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/components/OptionButton.tsx",
                            lineNumber: 43,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/components/OptionButton.tsx",
                    lineNumber: 41,
                    columnNumber: 9
                }, this),
                address && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                    className: "text-sm font-normal opacity-90",
                    children: address
                }, void 0, false, {
                    fileName: "[project]/src/components/OptionButton.tsx",
                    lineNumber: 48,
                    columnNumber: 11
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/src/components/OptionButton.tsx",
            lineNumber: 40,
            columnNumber: 7
        }, this)
    }, void 0, false, {
        fileName: "[project]/src/components/OptionButton.tsx",
        lineNumber: 28,
        columnNumber: 5
    }, this);
}
_c = OptionButton;
var _c;
__turbopack_context__.k.register(_c, "OptionButton");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/components/WinnerCard.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "WinnerCard",
    ()=>WinnerCard
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
"use client";
;
function WinnerCard({ name, voteCount, address }) {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "winner-reveal rounded-3xl border-4 border-[#6d28d9] bg-gradient-to-br from-[#6d28d9] to-[#7c3aed] p-8 text-white shadow-2xl",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                className: "mb-2 text-sm font-semibold uppercase tracking-wider text-white/80",
                children: "Winner!"
            }, void 0, false, {
                fileName: "[project]/src/components/WinnerCard.tsx",
                lineNumber: 12,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                className: "text-3xl font-bold md:text-4xl",
                children: name
            }, void 0, false, {
                fileName: "[project]/src/components/WinnerCard.tsx",
                lineNumber: 15,
                columnNumber: 7
            }, this),
            address && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                className: "mt-1 text-base text-white/90",
                children: address
            }, void 0, false, {
                fileName: "[project]/src/components/WinnerCard.tsx",
                lineNumber: 17,
                columnNumber: 9
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                className: "mt-2 text-lg text-white/90",
                children: [
                    voteCount,
                    " votes"
                ]
            }, void 0, true, {
                fileName: "[project]/src/components/WinnerCard.tsx",
                lineNumber: 19,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/src/components/WinnerCard.tsx",
        lineNumber: 11,
        columnNumber: 5
    }, this);
}
_c = WinnerCard;
var _c;
__turbopack_context__.k.register(_c, "WinnerCard");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/app/room/[code]/page.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>RoomPage
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/navigation.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/client/app-dir/link.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/api.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$socket$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/socket.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$CountdownTimer$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/components/CountdownTimer.tsx [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$OptionButton$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/components/OptionButton.tsx [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$WinnerCard$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/components/WinnerCard.tsx [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
"use client";
;
;
;
;
;
;
;
;
function RoomPage() {
    _s();
    const params = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useParams"])();
    const router = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRouter"])();
    const code = params?.code ?? "";
    const [room, setRoom] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [loading, setLoading] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(true);
    const [error, setError] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])("");
    const [newOption, setNewOption] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])("");
    const [addingOption, setAddingOption] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const [startingVote, setStartingVote] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const [locationError, setLocationError] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])("");
    const [votedId, setVotedId] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const MAX_OPTIONS = 4;
    const userId = ("TURBOPACK compile-time truthy", 1) ? localStorage.getItem("userId") : "TURBOPACK unreachable";
    const fetchRoom = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "RoomPage.useCallback[fetchRoom]": async ()=>{
            if (!code) return;
            try {
                const r = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["getRoom"])(code);
                setRoom(r);
                setError("");
            } catch (err) {
                setError(err instanceof Error ? err.message : "Room not found");
            } finally{
                setLoading(false);
            }
        }
    }["RoomPage.useCallback[fetchRoom]"], [
        code
    ]);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$socket$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRoomUpdates"])(code, {
        "RoomPage.useRoomUpdates": (payload)=>{
            setRoom(payload.room);
        }
    }["RoomPage.useRoomUpdates"]);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "RoomPage.useEffect": ()=>{
            fetchRoom();
        }
    }["RoomPage.useEffect"], [
        fetchRoom
    ]);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "RoomPage.useEffect": ()=>{
            if (!code || room?.status !== "voting") return;
            const interval = setInterval(fetchRoom, 2000);
            return ({
                "RoomPage.useEffect": ()=>clearInterval(interval)
            })["RoomPage.useEffect"];
        }
    }["RoomPage.useEffect"], [
        code,
        room?.status,
        fetchRoom
    ]);
    const isHost = userId === room?.hostId;
    const handleAddOption = async (e)=>{
        e.preventDefault();
        if (!newOption.trim() || !userId) return;
        setAddingOption(true);
        try {
            await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["addOption"])(code, newOption.trim(), userId);
            setNewOption("");
            await fetchRoom();
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to add");
        } finally{
            setAddingOption(false);
        }
    };
    const handleVote = async (optionId)=>{
        if (!userId || votedId || room?.status !== "voting") return;
        try {
            await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["vote"])(code, optionId, userId);
            setVotedId(optionId);
            await fetchRoom();
        } catch (err) {
            setError(err instanceof Error ? err.message : "Vote failed");
        }
    };
    const startVotingWithLocation = async (lat, lng)=>{
        if (!userId || !isHost) return;
        setStartingVote(true);
        setLocationError("");
        try {
            await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["startTimer"])(code, {
                userId,
                durationSeconds: 60,
                latitude: lat,
                longitude: lng
            });
            await fetchRoom();
        } catch (err) {
            setLocationError(err instanceof Error ? err.message : "Failed to start");
        } finally{
            setStartingVote(false);
        }
    };
    const handleStartTimer = async ()=>{
        if (!userId || !isHost) return;
        setStartingVote(true);
        setLocationError("");
        const getLocation = ()=>new Promise((resolve, reject)=>{
                if (!navigator.geolocation) {
                    reject(new Error("Geolocation not supported"));
                    return;
                }
                navigator.geolocation.getCurrentPosition((pos)=>resolve({
                        lat: pos.coords.latitude,
                        lng: pos.coords.longitude
                    }), (err)=>reject(new Error(err.message ?? "Could not get location")), {
                    enableHighAccuracy: true,
                    timeout: 10000
                });
            });
        try {
            const { lat, lng } = await getLocation();
            await startVotingWithLocation(lat, lng);
        } catch (err) {
            const msg = err instanceof Error ? err.message : "Failed to start";
            setLocationError(msg);
        } finally{
            setStartingVote(false);
        }
    };
    const handleStartWithDemoLocation = ()=>{
        startVotingWithLocation(37.7749, -122.4194);
    };
    const handleRestart = async ()=>{
        if (!userId || !isHost) return;
        try {
            const r = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["restartRoom"])(code, userId);
            setRoom(r);
            setVotedId(null);
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to restart");
        }
    };
    if (loading) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "flex min-h-screen items-center justify-center bg-[#f8fafc]",
            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "text-xl font-semibold text-[#1e1b4b]",
                children: "Loading..."
            }, void 0, false, {
                fileName: "[project]/src/app/room/[code]/page.tsx",
                lineNumber: 161,
                columnNumber: 9
            }, this)
        }, void 0, false, {
            fileName: "[project]/src/app/room/[code]/page.tsx",
            lineNumber: 160,
            columnNumber: 7
        }, this);
    }
    if (error && !room) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "flex min-h-screen flex-col items-center justify-center gap-4 bg-[#f8fafc] p-6",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                    className: "text-lg text-[#dc2626]",
                    children: error
                }, void 0, false, {
                    fileName: "[project]/src/app/room/[code]/page.tsx",
                    lineNumber: 169,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"], {
                    href: "/",
                    className: "rounded-xl bg-[#6d28d9] px-6 py-3 font-semibold text-white hover:bg-[#5b21b6]",
                    children: "Go Home"
                }, void 0, false, {
                    fileName: "[project]/src/app/room/[code]/page.tsx",
                    lineNumber: 170,
                    columnNumber: 9
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/src/app/room/[code]/page.tsx",
            lineNumber: 168,
            columnNumber: 7
        }, this);
    }
    if (!room) return null;
    const winner = (()=>{
        if (room.status !== "finished" || room.options.length === 0) return null;
        const maxVotes = Math.max(...room.options.map((o)=>o.voteCount));
        const tops = room.options.filter((o)=>o.voteCount === maxVotes);
        return tops[Math.floor(Math.random() * tops.length)] ?? null;
    })();
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "min-h-screen bg-[#f8fafc] p-4 md:p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("header", {
                className: "mb-6 flex items-center justify-between",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"], {
                        href: "/",
                        className: "text-[#6d28d9] font-semibold hover:underline",
                        children: "← Exit"
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 192,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "rounded-xl bg-[#1e1b4b] px-4 py-2",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-sm text-white/80",
                                children: "Room"
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 199,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "text-xl font-bold tracking-widest text-white",
                                children: room.code
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 200,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 198,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/room/[code]/page.tsx",
                lineNumber: 191,
                columnNumber: 7
            }, this),
            room.status === "waiting" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "mx-auto max-w-2xl space-y-6",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                        className: "text-center text-2xl font-bold text-[#1e1b4b]",
                        children: "Add up to 4 restaurant suggestions"
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 206,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "text-center text-sm text-[#64748b]",
                        children: "We'll find nearby restaurants matching these when voting starts."
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 209,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("form", {
                        onSubmit: handleAddOption,
                        className: "flex gap-2",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("input", {
                                type: "text",
                                value: newOption,
                                onChange: (e)=>setNewOption(e.target.value),
                                placeholder: "e.g. Sushi, Thai, Pizza",
                                maxLength: 64,
                                disabled: room.options.length >= MAX_OPTIONS,
                                className: "flex-1 rounded-xl border-2 border-[#e2e8f0] px-4 py-3 focus:border-[#6d28d9] focus:outline-none disabled:bg-[#f1f5f9]"
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 216,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                type: "submit",
                                disabled: addingOption || !newOption.trim() || room.options.length >= MAX_OPTIONS,
                                className: "rounded-xl bg-[#6d28d9] px-6 py-3 font-bold text-white hover:bg-[#5b21b6] disabled:opacity-50",
                                children: "Add"
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 225,
                                columnNumber: 13
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 212,
                        columnNumber: 11
                    }, this),
                    room.options.length >= MAX_OPTIONS && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "text-center text-sm font-medium text-[#6d28d9]",
                        children: "Maximum 4 suggestions. Click Start voting when ready."
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 238,
                        columnNumber: 13
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "space-y-3",
                        children: room.options.length === 0 ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "py-8 text-center text-[#64748b]",
                            children: "No options yet. Add up to 4 suggestions above!"
                        }, void 0, false, {
                            fileName: "[project]/src/app/room/[code]/page.tsx",
                            lineNumber: 244,
                            columnNumber: 15
                        }, this) : room.options.map((opt)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-2xl border-2 border-[#e2e8f0] bg-white px-6 py-4 font-medium text-[#1e1b4b]",
                                children: opt.name
                            }, opt.id, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 249,
                                columnNumber: 17
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 242,
                        columnNumber: 11
                    }, this),
                    isHost && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["Fragment"], {
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                onClick: handleStartTimer,
                                disabled: room.options.length < 2 || startingVote,
                                className: "mt-6 w-full rounded-2xl bg-[#059669] py-4 text-xl font-bold text-white shadow-lg hover:bg-[#047857] disabled:opacity-50 disabled:cursor-not-allowed",
                                children: startingVote ? "Finding restaurants nearby..." : "Start voting (60 sec)"
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 260,
                                columnNumber: 15
                            }, this),
                            locationError && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "space-y-2",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "text-center text-sm text-[#dc2626]",
                                        children: [
                                            locationError,
                                            " — Use localhost or enable location."
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/room/[code]/page.tsx",
                                        lineNumber: 271,
                                        columnNumber: 19
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        type: "button",
                                        onClick: handleStartWithDemoLocation,
                                        disabled: startingVote,
                                        className: "w-full rounded-xl border-2 border-dashed border-[#6d28d9] py-2 text-sm font-medium text-[#6d28d9] hover:bg-[#f3e8ff] disabled:opacity-50",
                                        children: "Continue with demo location"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/room/[code]/page.tsx",
                                        lineNumber: 274,
                                        columnNumber: 19
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 270,
                                columnNumber: 17
                            }, this)
                        ]
                    }, void 0, true),
                    !isHost && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "text-center text-[#64748b]",
                        children: "Waiting for host to start voting..."
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 287,
                        columnNumber: 13
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/room/[code]/page.tsx",
                lineNumber: 205,
                columnNumber: 9
            }, this),
            room.status === "voting" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "mx-auto max-w-2xl space-y-6",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex flex-col items-center gap-4",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "text-lg font-semibold text-[#1e1b4b]",
                                children: "Time remaining"
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 297,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$CountdownTimer$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__["CountdownTimer"], {
                                endTime: room.endTime,
                                onComplete: fetchRoom,
                                size: "lg"
                            }, void 0, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 298,
                                columnNumber: 13
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 296,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "space-y-4",
                        children: room.options.map((opt, i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$OptionButton$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__["OptionButton"], {
                                name: opt.name,
                                voteCount: opt.voteCount,
                                address: opt.address,
                                colorIndex: i,
                                disabled: !!votedId,
                                selected: votedId === opt.id,
                                onClick: ()=>handleVote(opt.id)
                            }, opt.id, false, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 306,
                                columnNumber: 15
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 304,
                        columnNumber: 11
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/room/[code]/page.tsx",
                lineNumber: 295,
                columnNumber: 9
            }, this),
            room.status === "finished" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "mx-auto max-w-xl space-y-8",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                        className: "text-center text-2xl font-bold text-[#1e1b4b]",
                        children: "Results"
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 323,
                        columnNumber: 11
                    }, this),
                    winner && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$WinnerCard$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__["WinnerCard"], {
                        name: winner.name,
                        voteCount: winner.voteCount,
                        address: winner.address
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 327,
                        columnNumber: 13
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "space-y-2",
                        children: room.options.sort((a, b)=>b.voteCount - a.voteCount).map((opt)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "flex flex-col gap-0.5 rounded-xl border-2 border-[#e2e8f0] bg-white px-6 py-3",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex items-center justify-between",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "font-medium",
                                                children: opt.name
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                                lineNumber: 342,
                                                columnNumber: 21
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "text-[#64748b]",
                                                children: [
                                                    opt.voteCount,
                                                    " votes"
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                                lineNumber: 343,
                                                columnNumber: 21
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/room/[code]/page.tsx",
                                        lineNumber: 341,
                                        columnNumber: 19
                                    }, this),
                                    opt.address && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "text-sm text-[#64748b]",
                                        children: opt.address
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/room/[code]/page.tsx",
                                        lineNumber: 346,
                                        columnNumber: 21
                                    }, this)
                                ]
                            }, opt.id, true, {
                                fileName: "[project]/src/app/room/[code]/page.tsx",
                                lineNumber: 337,
                                columnNumber: 17
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 333,
                        columnNumber: 11
                    }, this),
                    isHost && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                        onClick: handleRestart,
                        className: "w-full rounded-2xl bg-[#6d28d9] py-4 text-xl font-bold text-white hover:bg-[#5b21b6]",
                        children: "Restart session"
                    }, void 0, false, {
                        fileName: "[project]/src/app/room/[code]/page.tsx",
                        lineNumber: 352,
                        columnNumber: 13
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/room/[code]/page.tsx",
                lineNumber: 322,
                columnNumber: 9
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/src/app/room/[code]/page.tsx",
        lineNumber: 190,
        columnNumber: 5
    }, this);
}
_s(RoomPage, "7wQm3ghCI05zNUqWymNaY4UgVrk=", false, function() {
    return [
        __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useParams"],
        __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRouter"],
        __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$socket$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRoomUpdates"]
    ];
});
_c = RoomPage;
var _c;
__turbopack_context__.k.register(_c, "RoomPage");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
]);

//# sourceMappingURL=src_f518a498._.js.map