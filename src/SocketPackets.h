
// packet types used to identify transport layer (engine.io) packets
typedef enum {
    PacketTypeOpen = 0,
    PacketTypeClose = 1,
    PacketTypePing = 2,
    PacketTypePong = 3,
    PacketTypeMessage = 4,
    PacketTypeUpgrade = 5,
} PacketType;
