

#ifndef SETUP_ETH
#define SETUP_ETH
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

/************************** Typedef Definitions *****************************/
typedef char EthernetFrame[XEMACPS_MAX_VLAN_FRAME_SIZE_JUMBO] __attribute__ ((aligned(64)));

int eth_send(XEmacPs * emac_pointer);
int Eth_Initialize(XScuGic * intc_pointer, XEmacPs * emac_pointer, u16 emac_dev_id, u16 emac_intr_id);

#endif // SETUP_ETH
