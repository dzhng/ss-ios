
// responder ID used to identify socketstream server packets
typedef enum {
    ResponderTypeEvent = '0',
    ResponderTypeRPC = '1',
    ResponderTypeSystem = 'X',
} ResponderType;
