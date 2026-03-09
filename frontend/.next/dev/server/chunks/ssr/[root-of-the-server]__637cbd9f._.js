module.exports = [
"[externals]/next/dist/compiled/next-server/app-page-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-page-turbo.runtime.dev.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/action-async-storage.external.js [external] (next/dist/server/app-render/action-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/action-async-storage.external.js", () => require("next/dist/server/app-render/action-async-storage.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/work-unit-async-storage.external.js [external] (next/dist/server/app-render/work-unit-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/work-unit-async-storage.external.js", () => require("next/dist/server/app-render/work-unit-async-storage.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/work-async-storage.external.js [external] (next/dist/server/app-render/work-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/work-async-storage.external.js", () => require("next/dist/server/app-render/work-async-storage.external.js"));

module.exports = mod;
}),
"[project]/src/lib/api.ts [app-ssr] (ecmascript)", ((__turbopack_context__) => {
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
const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";
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
const USE_MOCK = process.env.NEXT_PUBLIC_USE_MOCK === "true";
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
        const { mockCreateRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
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
        const { mockJoinRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
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
        const { mockAddOption } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
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
        const { mockVote } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
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
        const { mockStartTimer } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
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
        const { mockRestartRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
        return mockRestartRoom(roomCode);
    });
}
async function getRoom(roomCode) {
    return tryApi(()=>fetchApi(`/api/rooms/${roomCode}`), async ()=>{
        const { mockGetRoom } = await __turbopack_context__.A("[project]/src/lib/mock.ts [app-ssr] (ecmascript, async loader)");
        const room = mockGetRoom(roomCode);
        if (!room) throw new Error("Room not found");
        return room;
    });
}
;
}),
"[project]/src/app/create/page.tsx [app-ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>CreateRoomPage
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react-jsx-dev-runtime.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/navigation.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/client/app-dir/link.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/api.ts [app-ssr] (ecmascript)");
"use client";
;
;
;
;
;
function CreateRoomPage() {
    const router = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$navigation$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["useRouter"])();
    const [name, setName] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["useState"])("");
    const [loading, setLoading] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["useState"])(false);
    const [error, setError] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["useState"])("");
    const handleSubmit = async (e)=>{
        e.preventDefault();
        if (!name.trim()) return;
        setLoading(true);
        setError("");
        try {
            const { room, user } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$api$2e$ts__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["createRoom"])(name.trim());
            localStorage.setItem("userId", user.id);
            localStorage.setItem("userName", user.name);
            router.push(`/room/${room.code}`);
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to create room");
        } finally{
            setLoading(false);
        }
    };
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "flex min-h-screen flex-col items-center justify-center bg-[#f8fafc] p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                href: "/",
                className: "absolute left-4 top-4 text-[#6d28d9] font-semibold hover:underline",
                children: "← Back"
            }, void 0, false, {
                fileName: "[project]/src/app/create/page.tsx",
                lineNumber: 33,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("main", {
                className: "w-full max-w-md",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                        className: "mb-8 text-center text-2xl font-bold text-[#1e1b4b]",
                        children: "Create a Room"
                    }, void 0, false, {
                        fileName: "[project]/src/app/create/page.tsx",
                        lineNumber: 40,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("form", {
                        onSubmit: handleSubmit,
                        className: "rounded-3xl border-4 border-[#6d28d9] bg-white p-8 shadow-xl",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("label", {
                                htmlFor: "name",
                                className: "mb-2 block font-semibold text-[#475569]",
                                children: "Your name"
                            }, void 0, false, {
                                fileName: "[project]/src/app/create/page.tsx",
                                lineNumber: 47,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("input", {
                                id: "name",
                                type: "text",
                                value: name,
                                onChange: (e)=>setName(e.target.value),
                                placeholder: "Host",
                                required: true,
                                maxLength: 32,
                                className: "mb-6 w-full rounded-xl border-2 border-[#e2e8f0] px-4 py-3 text-lg focus:border-[#6d28d9] focus:outline-none"
                            }, void 0, false, {
                                fileName: "[project]/src/app/create/page.tsx",
                                lineNumber: 50,
                                columnNumber: 11
                            }, this),
                            error && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mb-4 text-sm text-[#dc2626]",
                                children: error
                            }, void 0, false, {
                                fileName: "[project]/src/app/create/page.tsx",
                                lineNumber: 61,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                type: "submit",
                                disabled: loading,
                                className: "w-full rounded-xl bg-[#6d28d9] py-4 text-lg font-bold text-white transition hover:bg-[#5b21b6] disabled:opacity-50",
                                children: loading ? "Creating..." : "Create Room"
                            }, void 0, false, {
                                fileName: "[project]/src/app/create/page.tsx",
                                lineNumber: 63,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/create/page.tsx",
                        lineNumber: 43,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/create/page.tsx",
                lineNumber: 39,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/src/app/create/page.tsx",
        lineNumber: 32,
        columnNumber: 5
    }, this);
}
}),
];

//# sourceMappingURL=%5Broot-of-the-server%5D__637cbd9f._.js.map