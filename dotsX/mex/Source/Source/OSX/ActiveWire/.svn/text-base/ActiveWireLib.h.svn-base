#ifdef __cplusplus

extern "C"
{

#endif

#include <stdbool.h>
#include <time.h>

/* Event stuff */

enum event_types
{

	AW_EVENT_BOARD_CONNECTED,
	AW_EVENT_BOARD_DISCONNECTED,
	AW_EVENT_BOARD_DATA_CHANGED

};

typedef enum event_types AW_EVENT_TYPE;

struct aw_event
{

	unsigned char boardNumber;	/* Board that the event applies to. */
	AW_EVENT_TYPE eventType;	/* Event type; see event_types above. */
	unsigned char boardData[2];	/* A two-byte array containing the board's state when the event occurred. */
	struct timespec timestamp;	/* The time the event occurred. */

};

typedef struct aw_event *AW_EVENT;

struct aw_event_list
{

	AW_EVENT *events;
	unsigned short numberOfEvents;

};

typedef struct aw_event_list *AW_EVENT_LIST;

enum aw_delivery_method
{

	AW_DELIV_CALLBACK,	/* Deliver events immediatley via the three callbacks. */
	AW_DELIV_BUFFER,	/* Buffer events until they're acquired using aw_getEvents. */
	AW_DELIV_NONE		/* Disregard all events. */

};

typedef enum aw_delivery_method AW_DELIV_METHOD;

/* Define the possible errors, which will hopefully never see the light of day. */

enum aw_err
{

	AW_ERR_NONE,			/* No error */
	AW_ERR_NOT_INIT,		/* Not initialized */
	AW_ERR_ALREADY_INIT,	/* Already initialized */
	AW_ERR_INTERNAL,		/* Internal error */
	AW_ERR_LOCAL_SOCKET,	/* Unable to create socket to interface with server */
	AW_ERR_CONTACT_SERV,	/* Unable to contact server */
	AW_ERR_AUTH,			/* Unable to authorize client, password is probably incorrect */
	AW_ERR_ENCRYPT,			/* Unable to encrypt password for transit to server */
	AW_ERR_LEN_NOT_DIV_2	/* Length is not divisible by two. */

};

typedef enum aw_err AW_ERR;

/* Callback Typedefs */

typedef void (*BoardConnectedCallback) (AW_EVENT event);

typedef void (*BoardDisconnectedCallback) (AW_EVENT event);

typedef void (*BoardDataChangedCallback) (AW_EVENT event);

/* Functions */

AW_ERR aw_init();
AW_ERR aw_initWithAddress(unsigned char *address, unsigned char *password);

void aw_close();

AW_ERR aw_setDirectionsOfPinSets(unsigned char boardNumber, unsigned char firstPinSetDirections, unsigned char secondPinSetDirections);

AW_ERR aw_readData(unsigned char boardNumber, unsigned char *buffer, unsigned short length);

AW_ERR aw_writeData(unsigned char boardNumber, unsigned char *data, unsigned short length);

AW_ERR aw_setCallbacksAndDeliveryMethod(BoardConnectedCallback newBoardConnectedCallback,
										BoardDisconnectedCallback newBoardDisconnectedCallback,
										BoardDataChangedCallback newBoardDataChangedCallback,
										AW_DELIV_METHOD newDeliveryMethod, unsigned short newMaxEvents); /* Callbacks only used when deliveryMethod == AW_DELIV_CALLBACK,
																											maxEvents is only used when deliveryMethod == AW_DELIV_BUFFER. */

AW_EVENT_LIST aw_getEvents();
void aw_clearEvents();

AW_ERR aw_numberOfConnectedBoards(unsigned char *numberOfBoards);

void decimalArrayToBinary(unsigned char *decimalArray, unsigned short arrayLength, unsigned char *binaryArray);
void binaryArrayToDecimal(unsigned char *binaryArray, unsigned short arrayLength, unsigned char *decimalArray);

#ifdef __cplusplus

}

#endif