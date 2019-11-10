

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
#include "xemacps.h"        /* defines XEmacPs API */
#include "xscugic.h"
#include "xil_exception.h"

/************************** Constant Definitions *****************************/
// EMAC
#define EMACPS_DEVICE_ID    XPAR_XEMACPS_0_DEVICE_ID
#define EMACPS_IRPT_INTR    XPS_GEM0_INT_ID
#define EMACPS_SLCR_DIV_MASK    0xFC0FC0FF
#define EMACPS_LOOPBACK_SPEED_1G 1000
// Interrupts
#define INTC_DEVICE_ID      XPAR_SCUGIC_SINGLE_DEVICE_ID
// PHY
#define PHY_DETECT_REG1 2
#define PHY_DETECT_REG2 3
#define PHY_REG0_1000           0x0140
#define PHY_REG0_LOOPBACK       0x4000
#define PHY_REG0_AUTONEGOTIATE  0x1000
#define PHY_REG21_1000          0x0070
// SLCR setting
#define SLCR_LOCK_ADDR              (XPS_SYS_CTRL_BASEADDR + 0x4)
#define SLCR_UNLOCK_ADDR            (XPS_SYS_CTRL_BASEADDR + 0x8)
#define SLCR_GEM0_CLK_CTRL_ADDR     (XPS_SYS_CTRL_BASEADDR + 0x140)
#define SLCR_GEM1_CLK_CTRL_ADDR     (XPS_SYS_CTRL_BASEADDR + 0x144)
#define SLCR_LOCK_KEY_VALUE         0x767B
#define SLCR_UNLOCK_KEY_VALUE       0xDF0D
#define SLCR_ADDR_GEM_RST_CTRL      (XPS_SYS_CTRL_BASEADDR + 0x214)
// Buffer Descriptor
#define RXBD_CNT       32   // Number of RX BDs
#define TXBD_CNT       32   // Number of TX BDs
/************************** Struct Definitions ****************************/
static XScuGic IntcInstance;
XEmacPs EmacPsInstance;
/************************** Variable Definitions ****************************/
char EmacPsMAC[] = { 0x00, 0x0a, 0x35, 0x01, 0x02, 0x03 };
u32 GemVersion;
volatile s32 FramesTx;  // Frames sent
volatile s32 FramesRx;  // Frames received
u8 bd_space[0x100000] __attribute__ ((aligned (0x100000)));
u8 *RxBdSpacePtr;
u8 *TxBdSpacePtr;
/****************************************************************************/
int main(void) {
    LONG Status;

    EmacpsDelay(1);
    xil_printf("Starting...\r\n");

    Status = Eth_Initialize(&IntcInstance, &EmacPsInstance, EMACPS_DEVICE_ID, EMACPS_IRPT_INTR);

    xil_printf("Ending...\r\n");
    return XST_SUCCESS;
}


int Eth_Initialize(XScuGic * intc_pointer, XEmacPs * emac_pointer, u16 emac_dev_id, u16 emac_intr_id) {
    // Define variables
    u32 ClkCntrl;
    u32 PhyAddr;
    u16 PhyIdentity;

    u16 PhyReg0  = 0;
    u16 PhyReg1;
    u16 PhyReg21  = 0;
    // Define structures
    XEmacPs_Config *emac_config;
    XEmacPs_Bd bd_template;
    XScuGic_Config *gic_config;

    emac_config = XEmacPs_LookupConfig(emac_dev_id);
    XEmacPs_CfgInitialize(emac_pointer, emac_config, emac_config->BaseAddress);
    GemVersion = ((Xil_In32(Config->BaseAddress + 0xFC)) >> 16) & 0xFFF;

    // GEM0 1G clock configuration
    ClkCntrl = *(volatile unsigned int *)(SLCR_GEM0_CLK_CTRL_ADDR);
    ClkCntrl &= EMACPS_SLCR_DIV_MASK;
    ClkCntrl |= (XPAR_PS7_ETHERNET_0_ENET_SLCR_1000MBPS_DIV1 << 20);
    ClkCntrl |= (XPAR_PS7_ETHERNET_0_ENET_SLCR_1000MBPS_DIV0 << 8);
    *(volatile unsigned int *)(SLCR_GEM0_CLK_CTRL_ADDR) = ClkCntrl;
    // SLCR lock
    *(unsigned int *)(SLCR_LOCK_ADDR) = SLCR_LOCK_KEY_VALUE;
    sleep(1);
    // Set the MAC address
    XEmacPs_SetMacAddress(emac_pointer, EmacPsMAC, 1);
    // Setup callbacks
    XEmacPs_SetHandler(emac_pointer, XEMACPS_HANDLER_DMASEND, (void *) XEmacPsSendHandler, emac_pointer);
    XEmacPs_SetHandler(emac_pointer, XEMACPS_HANDLER_DMARECV, (void *) XEmacPsRecvHandler, emac_pointer);
    XEmacPs_SetHandler(emac_pointer, XEMACPS_HANDLER_ERROR, (void *) XEmacPsErrorHandler, emac_pointer);
    // Allocate 1MB uncached memory for BDs
    Xil_SetTlbAttributes((INTPTR)bd_space, DEVICE_MEMORY);
    // Allocate and setup RX and TX BD space
    RxBdSpacePtr = &(bd_space[0]);
    TxBdSpacePtr = &(bd_space[0x10000]);
    XEmacPs_BdClear(&bd_template);
    // Create the RX BD ring
    XEmacPs_BdRingCreate(&(XEmacPs_GetRxRing(emac_pointer)), (UINTPTR) RxBdSpacePtr, (UINTPTR) RxBdSpacePtr, XEMACPS_BD_ALIGNMENT, RXBD_CNT);
    XEmacPs_BdRingClone(&(XEmacPs_GetRxRing(emac_pointer)), &bd_template, XEMACPS_RECV);
    // Setup TX BD space
    XEmacPs_BdClear(&bd_template);
    XEmacPs_BdSetStatus(&bd_template, XEMACPS_TXBUF_USED_MASK);
    // Create the TX BD ring
    XEmacPs_BdRingCreate(&(XEmacPs_GetTxRing(emac_pointer)), (UINTPTR) TxBdSpacePtr, (UINTPTR) TxBdSpacePtr, XEMACPS_BD_ALIGNMENT, TXBD_CNT);
    XEmacPs_BdRingClone(&(XEmacPs_GetTxRing(emac_pointer)), &bd_template, XEMACPS_SEND);
    // Config MDIO & PHY
    XEmacPs_SetMdioDivisor(emac_pointer, MDC_DIV_224);
    sleep(1);
    PhyAddr = XEmacPsDetectPHY(emac_pointer);
    XEmacPs_PhyRead(emac_pointer, PhyAddr, PHY_DETECT_REG1, &PhyIdentity);
    // Setup speed/duplex
    PhyReg0 |= PHY_REG0_1000;
    PhyReg21 |= PHY_REG21_1000;
    XEmacPs_PhyWrite(emac_pointer, PhyAddr, 0, PhyReg0);
    if (XEmacPs_PhyRead(emac_pointer, PhyAddr, 0, &PhyReg0) != XST_SUCCESS) xil_printf("ERROR: PHY speed setup");
    XEmacPs_PhyRead(emac_pointer, PhyAddr, 0, &PhyReg0);
    PhyReg0 &= ~PHY_REG0_LOOPBACK;
    PhyReg0 |= PHY_REG0_AUTONEGOTIATE;
    XEmacPs_PhyWrite(emac_pointer, PhyAddr, 0, PhyReg0);
    sleep(1);
    XEmacPs_PhyRead(emac_pointer, PhyAddr, 1, &PhyReg1);
    xil_printf("Auto-negotiating");
    while (!(PhyReg1 & 0x0020))
        XEmacPs_PhyRead(emac_pointer, PhyAddr, 1, &PhyReg1); xil_printf(".\r\n"); sleep(1);
    while (!(PhyReg1 & 0x0004))
        XEmacPs_PhyRead(emac_pointer, PhyAddr, 1, &PhyReg1); xil_printf(".\r\n"); sleep(1);
    xil_printf("Link is Up\r\n");
    sleep(1);
    XEmacPs_SetOperatingSpeed(emac_pointer, EMACPS_LOOPBACK_SPEED_1G);
    // Setup the interrupt controller and enable interrupts
    Xil_ExceptionInit();
    gic_config = XScuGic_LookupConfig(INTC_DEVICE_ID);
    XScuGic_CfgInitialize(intc_pointer, gic_config, gic_config->CpuBaseAddress);
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, intc_pointer);
    XScuGic_Connect(intc_pointer, emac_intr_id, (Xil_InterruptHandler) XEmacPs_IntrHandler, (void *) emac_pointer);
    XScuGic_Enable(intc_pointer, emac_intr_id);
    Xil_ExceptionEnable(); // Enable interrupts in PS

}


/****************************************************************************/
static void XEmacPsSendHandler(void *Callback) {
    XEmacPs *EmacPsInstancePtr = (XEmacPs *) Callback;
    // Disable the transmit related interrupts
    XEmacPs_IntDisable(EmacPsInstancePtr, (XEMACPS_IXR_TXCOMPL_MASK | XEMACPS_IXR_TX_ERR_MASK));
    FramesTx++;
}
/****************************************************************************/
static void XEmacPsRecvHandler(void *Callback) {
    XEmacPs *EmacPsInstancePtr = (XEmacPs *) Callback;
    // Disable the transmit related interrupts
    XEmacPs_IntDisable(EmacPsInstancePtr, (XEMACPS_IXR_FRAMERX_MASK | XEMACPS_IXR_RX_ERR_MASK));
    FramesRx++;
    if (EmacPsInstancePtr->Config.IsCacheCoherent == 0)
        Xil_DCacheInvalidateRange((UINTPTR)&RxFrame, sizeof(EthernetFrame));
}
/****************************************************************************/
static void XEmacPsErrorHandler(void *Callback, u8 Direction, u32 ErrorWord) {
    XEmacPs *EmacPsInstancePtr = (XEmacPs *) Callback;
    DeviceErrors++;
    switch (Direction) {
    case XEMACPS_RECV:
        if (ErrorWord & XEMACPS_RXSR_HRESPNOK_MASK) xil_printf("ERROR: Receive DMA error");
        if (ErrorWord & XEMACPS_RXSR_RXOVR_MASK)    xil_printf("ERROR: Receive over run");
        if (ErrorWord & XEMACPS_RXSR_BUFFNA_MASK)   xil_printf("ERROR: Receive buffer not available");
        break;
    case XEMACPS_SEND:
        if (ErrorWord & XEMACPS_TXSR_HRESPNOK_MASK) xil_printf("ERROR: Transmit DMA error");
        if (ErrorWord & XEMACPS_TXSR_URUN_MASK)     xil_printf("ERROR: Transmit under run");
        if (ErrorWord & XEMACPS_TXSR_BUFEXH_MASK)   xil_printf("ERROR: Transmit buffer exhausted");
        if (ErrorWord & XEMACPS_TXSR_RXOVR_MASK)    xil_printf("ERROR: Transmit retry excessed limits");
        if (ErrorWord & XEMACPS_TXSR_FRAMERX_MASK)  xil_printf("ERROR: Transmit collision");
        if (ErrorWord & XEMACPS_TXSR_USEDREAD_MASK) xil_printf("ERROR: Transmit buffer not available");
        break;
    }
    // TODO: Reset device (EmacPsResetDevice(EmacPsInstancePtr))
}
/****************************************************************************/
u32 XEmacPsDetectPHY(XEmacPs * EmacPsInstancePtr) {
    u32 PhyAddr, Status;
    u16 reg1, reg2;

    for (PhyAddr = 0; PhyAddr <= 31; PhyAddr++) {
        Status = XEmacPs_PhyRead(EmacPsInstancePtr, PhyAddr, PHY_DETECT_REG1, &reg1);
        Status |= XEmacPs_PhyRead(EmacPsInstancePtr, PhyAddr, PHY_DETECT_REG2, &reg2);
        if ((Status == XST_SUCCESS) && (reg1 > 0x0000) && (reg1 < 0xffff) && (reg2 > 0x0000) && (reg2 < 0xffff))
            return PhyAddr; // Found a valid PHY address
    }
    return PhyAddr; // default to 32(max of iteration)
}

