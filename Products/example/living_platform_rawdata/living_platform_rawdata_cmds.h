#ifndef __LIVING_PLATFORM_RAWDATA_CMDS_H__
#define __LIVING_PLATFORM_RAWDATA_CMDS_H__

#define MAX_DEVICES_META_NUM (0)

#ifdef MANUFACT_AP_FIND_ENABLE
#define MANUAP_CONTROL_KEY "manuap"
#endif

extern int living_platform_rawdata_register_cmds(void);
extern void living_platform_rawdata_start_netmgr(void *p);
extern void living_platform_rawdata_do_awss_dev_ap(void);
extern void living_platform_rawdata_awss_reset(void);
extern void living_platform_rawdata_do_awss_active(void);
extern void living_platform_rawdata_do_awss(void);
#endif
