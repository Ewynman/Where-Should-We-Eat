(globalThis.TURBOPACK || (globalThis.TURBOPACK = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/src/lib/mock.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "mockAddOption",
    ()=>mockAddOption,
    "mockCreateRoom",
    ()=>mockCreateRoom,
    "mockGetRoom",
    ()=>mockGetRoom,
    "mockJoinRoom",
    ()=>mockJoinRoom,
    "mockRestartRoom",
    ()=>mockRestartRoom,
    "mockStartTimer",
    ()=>mockStartTimer,
    "mockVote",
    ()=>mockVote
]);
const MOCK_ROOMS = new Map();
let mockId = 0;
const id = ()=>`mock-${++mockId}`;
function generateCode() {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    for(let i = 0; i < 6; i++)code += chars[Math.floor(Math.random() * chars.length)];
    return code;
}
function mockCreateRoom(name) {
    let code = generateCode();
    while(MOCK_ROOMS.has(code))code = generateCode();
    const room = {
        id: id(),
        code,
        hostId: id(),
        status: "waiting",
        endTime: null,
        options: []
    };
    MOCK_ROOMS.set(code, room);
    const user = {
        id: room.hostId,
        roomId: room.id,
        name,
        hasVoted: false
    };
    return {
        room,
        user
    };
}
function mockJoinRoom(code, name) {
    const room = MOCK_ROOMS.get(code.toUpperCase());
    if (!room) throw new Error("Room not found");
    if (room.status === "finished") throw new Error("Room has ended");
    const user = {
        id: id(),
        roomId: room.id,
        name,
        hasVoted: false
    };
    return {
        room,
        user
    };
}
function mockGetRoom(code) {
    const room = MOCK_ROOMS.get(code.toUpperCase());
    if (!room) return undefined;
    if (room.status === "voting" && room.endTime) {
        const end = new Date(room.endTime).getTime();
        if (Date.now() >= end) {
            room.status = "finished";
        }
    }
    return room;
}
const MAX_OPTIONS = 4;
function mockAddOption(roomCode, name) {
    const room = MOCK_ROOMS.get(roomCode.toUpperCase());
    if (!room) throw new Error("Room not found");
    if (room.options.length >= MAX_OPTIONS) throw new Error("Maximum 4 suggestions");
    const existing = room.options.find((o)=>o.name.toLowerCase() === name.toLowerCase().trim());
    if (existing) throw new Error("Option already exists");
    const option = {
        id: id(),
        roomId: room.id,
        name: name.trim(),
        voteCount: 0
    };
    room.options = [
        ...room.options,
        option
    ];
    return option;
}
function mockVote(roomCode, optionId, userId) {
    const room = MOCK_ROOMS.get(roomCode.toUpperCase());
    if (!room) throw new Error("Room not found");
    const user = {
        id: userId,
        hasVoted: true
    }; // simplified
    const option = room.options.find((o)=>o.id === optionId);
    if (!option) throw new Error("Option not found");
    option.voteCount++;
    room.options = [
        ...room.options
    ];
}
const MOCK_ADDRESSES = [
    "123 Main St",
    "456 Oak Ave",
    "789 Elm Blvd",
    "321 Pine Rd"
];
function mockStartTimer(roomCode, durationSeconds, _latitude, _longitude) {
    const room = MOCK_ROOMS.get(roomCode.toUpperCase());
    if (!room) throw new Error("Room not found");
    // Simulate Google Places: enrich options with addresses
    room.options = room.options.map((o, i)=>({
            ...o,
            address: MOCK_ADDRESSES[i] ?? `${100 + i} Local St`
        }));
    room.status = "voting";
    room.endTime = new Date(Date.now() + durationSeconds * 1000).toISOString();
}
function mockRestartRoom(roomCode) {
    const room = MOCK_ROOMS.get(roomCode.toUpperCase());
    if (!room) throw new Error("Room not found");
    room.status = "waiting";
    room.endTime = null;
    room.options = room.options.map(({ id, roomId, name })=>({
            id,
            roomId,
            name,
            voteCount: 0
        }));
    return {
        ...room
    };
}
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
]);

//# sourceMappingURL=src_lib_mock_ts_f984a0b0._.js.map