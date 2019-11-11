

/***************************** Include Files ********************************/
#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xil_io.h"
#include "xil_exception.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_mmu.h"
#include "xemacps.h"        // XEmacPs API
#include "xscugic.h"
#include "xil_exception.h"
#include "sleep.h"
#include "../include/ethernet_driver.h"

/************************** Struct Definitions ******************************/
static XScuGic IntcInstance;
XEmacPs EmacPsInstance;
/****************************************************************************/
int main(void) {

    sleep(1);
    xil_printf("Starting...\r\n");

    Eth_Initialize(&IntcInstance, &EmacPsInstance, EMACPS_DEVICE_ID, EMACPS_IRPT_INTR);

    xil_printf("Ending...\r\n");
    return 0;
}

