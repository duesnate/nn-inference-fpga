

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
/************************** Constant Definitions ****************************/
/************************** Struct Definitions ******************************/
/************************** Variable Definitions ****************************/
char EmacPsMAC[] = { 0x00, 0x0a, 0x35, 0x01, 0x02, 0x03 };
char DestMACAddr[] = {0x04, 0x92, 0x26, 0xd8, 0x17, 0xfc};
u32 GemVersion;
volatile s32 FramesTx;      // Frames sent
volatile s32 FramesRx;      // Frames received
volatile s32 DeviceErrors;  // Error Count
u8 bd_space[0x100000] __attribute__ ((aligned (0x100000)));
u8 *RxBdSpacePtr;
u8 *TxBdSpacePtr;
u32 TxFrameLength;
EthernetFrame TxFrame;      /* Transmit buffer */
EthernetFrame RxFrame;      /* Receive buffer */
/*************************** Function Prototypes ****************************/
static void XEmacPsSendHandler(void *Callback);
static void XEmacPsRecvHandler(void *Callback);
static void XEmacPsErrorHandler(void *Callback, u8 Direction, u32 ErrorWord);
u32 XEmacPsDetectPHY(XEmacPs * EmacPsInstancePtr);
void EmacPsUtilFrameHdrFormatMAC(EthernetFrame * FramePtr, char *DestAddr);
void EmacPsUtilFrameHdrFormatType(EthernetFrame * FramePtr, u16 FrameType);
void EmacPsUtilFrameSetPayloadData(EthernetFrame * FramePtr, u32 PayloadSize);
void EmacPsUtilFrameMemClear(EthernetFrame * FramePtr);
/****************************************************************************/
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
    GemVersion = ((Xil_In32(emac_config->BaseAddress + 0xFC)) >> 16) & 0xFFF;

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
        {XEmacPs_PhyRead(emac_pointer, PhyAddr, 1, &PhyReg1); xil_printf(".\r\n"); sleep(1);}
    while (!(PhyReg1 & 0x0004))
        {XEmacPs_PhyRead(emac_pointer, PhyAddr, 1, &PhyReg1); xil_printf(".\r\n"); sleep(1);}
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

    for (int i=0;i<10;i++) {
        eth_send(emac_pointer);
        sleep(1);
    }
    // Stop device
    XEmacPs_Stop(emac_pointer);
    // Disable interrupts
    XScuGic_Disconnect(intc_pointer, emac_intr_id);
    return 0;
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
/****************************************************************************/
void EmacPsUtilFrameHdrFormatMAC(EthernetFrame * FramePtr, char *DestAddr) {
    char *Frame = (char *) FramePtr;
    char *SourceAddress = EmacPsMAC;
    s32 Index;
    // Destination address
    for (Index = 0; Index < XEMACPS_MAC_ADDR_SIZE; Index++)
        *Frame++ = *DestAddr++;
    // Source address
    for (Index = 0; Index < XEMACPS_MAC_ADDR_SIZE; Index++)
        *Frame++ = *SourceAddress++;
}
/****************************************************************************/
void EmacPsUtilFrameHdrFormatType(EthernetFrame * FramePtr, u16 FrameType) {
    char *Frame = (char *) FramePtr;
   //Increment to type field
    Frame = Frame + 12;
   //Do endian swap from little to big-endian.
    FrameType = Xil_EndianSwap16(FrameType);
   //Set the type
    *(u16 *) Frame = FrameType;
}
/****************************************************************************/
void EmacPsUtilFrameSetPayloadData(EthernetFrame * FramePtr, u32 PayloadSize) {
    u32 BytesLeft = PayloadSize;
    u8 *Frame;
    u16 Counter = 0;
    char mymessage[] = "The primary application of NN models in this project will be for image recognition and will focus primarily";
    // Set the frame pointer to the start of the payload area
    Frame = (u8 *) FramePtr + XEMACPS_HDR_SIZE;
    memcpy(Frame, mymessage, sizeof(mymessage));
    // // Insert 8 bit incrementing pattern
    // while (BytesLeft && (Counter < 256)) {
    //     *Frame++ = (u8) Counter++;
    //     BytesLeft--;
    // }
    // // Switch to 16 bit incrementing pattern
    // while (BytesLeft) {
    //     *Frame++ = (u8) (Counter >> 8); /* high */
    //     BytesLeft--;
    //     if (!BytesLeft) break;
    //     *Frame++ = (u8) Counter++;  /* low */
    //     BytesLeft--;
    // }
}
/****************************************************************************/
void EmacPsUtilFrameMemClear(EthernetFrame * FramePtr) {
    u32 *Data32Ptr = (u32 *) FramePtr;
    u32 WordsLeft = sizeof(EthernetFrame) / sizeof(u32);
    /* frame should be an integral number of words */
    while (WordsLeft--)
        *Data32Ptr++ = 0xDEADBEEF;
}
/****************************************************************************/
int eth_send(XEmacPs * emac_pointer) {
    u32 PayloadSize = 1000;
    u32 NumRxBuf = 0;
    u32 RxFrLen;
    XEmacPs_Bd *Bd1Ptr;
    XEmacPs_Bd *BdRxPtr;
    FramesRx = 0;
    FramesTx = 0;
    DeviceErrors = 0;
    TxFrameLength = XEMACPS_HDR_SIZE + PayloadSize;
    // Setup packet to be transmitted
    EmacPsUtilFrameHdrFormatMAC(&TxFrame, DestMACAddr);
    EmacPsUtilFrameHdrFormatType(&TxFrame, PayloadSize);
    EmacPsUtilFrameSetPayloadData(&TxFrame, PayloadSize);
    if (emac_pointer->Config.IsCacheCoherent == 0)
        Xil_DCacheFlushRange((UINTPTR)&TxFrame, sizeof(EthernetFrame));
    // Clear out receive packet memory area
    EmacPsUtilFrameMemClear(&RxFrame);
    if (emac_pointer->Config.IsCacheCoherent == 0)
        Xil_DCacheFlushRange((UINTPTR)&RxFrame, sizeof(EthernetFrame));
    // Allocate RX BDs since we do not know how many BDs will be used in advance, use RXBD_CNT here.
    XEmacPs_BdRingAlloc(&(XEmacPs_GetRxRing(emac_pointer)), 1, &BdRxPtr);
    // Setup the BD
    XEmacPs_BdSetAddressRx(BdRxPtr, (UINTPTR)&RxFrame);
    // Enqueue to HW
    XEmacPs_BdRingToHw(&(XEmacPs_GetRxRing(emac_pointer)), 1, BdRxPtr);
    // Allocate setup and enqueue 1 TX BD
    XEmacPs_BdRingAlloc(&(XEmacPs_GetTxRing(emac_pointer)), 1, &Bd1Ptr);
    // Setup first TX BD
    XEmacPs_BdSetAddressTx(Bd1Ptr, (UINTPTR)&TxFrame);
    XEmacPs_BdSetLength(Bd1Ptr, TxFrameLength);
    XEmacPs_BdClearTxUsed(Bd1Ptr);
    XEmacPs_BdSetLast(Bd1Ptr);
    // Enqueue to HW
    XEmacPs_BdRingToHw(&(XEmacPs_GetTxRing(emac_pointer)), 1, Bd1Ptr);
    if (emac_pointer->Config.IsCacheCoherent == 0)
        Xil_DCacheFlushRange((UINTPTR)Bd1Ptr, 64);
    // Set the Queue pointers
    XEmacPs_SetQueuePtr(emac_pointer, emac_pointer->RxBdRing.BaseBdAddr, 0, XEMACPS_RECV);
    XEmacPs_SetQueuePtr(emac_pointer, emac_pointer->TxBdRing.BaseBdAddr, 0, XEMACPS_SEND);
    // Start device
    XEmacPs_Start(emac_pointer);
    // Start TX
    XEmacPs_Transmit(emac_pointer);
    // Wait for TX complete
    while (!FramesTx);
    // Post process TX BDs
    if (XEmacPs_BdRingFromHwTx(&(XEmacPs_GetTxRing(emac_pointer)), 1, &Bd1Ptr) == 0)
        xil_printf("TxBDs were not ready for post processing\r\n");
    // Free up BD
    XEmacPs_BdRingFree(&(XEmacPs_GetTxRing(emac_pointer)), 1, Bd1Ptr);
    // Wiat for RX indication
    // while (!FramesRx);
    // // Post process RX BDs
    // NumRxBuf = XEmacPs_BdRingFromHwRx(&(XEmacPs_GetRxRing(emac_pointer)), 1, &BdRxPtr);
    // if (0 == NumRxBuf)
    //     xil_printf("ERROR: RxBD was not ready for post processing\r\n");
    // RxFrLen = XEmacPs_BdGetLength(BdRxPtr);
    // Free RX BD
    XEmacPs_BdRingFree(&(XEmacPs_GetRxRing(emac_pointer)), NumRxBuf, BdRxPtr);
    return 0;
}
