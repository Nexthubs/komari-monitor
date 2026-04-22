package api

import (
	"github.com/komari-monitor/komari/common"
	recordsdb "github.com/komari-monitor/komari/database/records"
)

func GetRecentReports(uuid string) ([]common.Report, error) {
	raw, _ := Records.Get(uuid)
	if reports, ok := raw.([]common.Report); ok && len(reports) > 0 {
		return reports, nil
	}

	report, err := GetLatestStoredReport(uuid)
	if err != nil || report == nil {
		return []common.Report{}, err
	}

	return []common.Report{*report}, nil
}

func GetLatestStoredReport(uuid string) (*common.Report, error) {
	recordList, err := recordsdb.GetLatestRecord(uuid)
	if err != nil {
		return nil, err
	}
	if len(recordList) == 0 {
		return nil, nil
	}

	record := recordList[0]
	tcpConnections := record.Connections - record.ConnectionsUdp
	if tcpConnections < 0 {
		tcpConnections = 0
	}

	return &common.Report{
		UUID: uuid,
		CPU: common.CPUReport{
			Usage: float64(record.Cpu),
		},
		Ram: common.RamReport{
			Total: record.RamTotal,
			Used:  record.Ram,
		},
		Swap: common.RamReport{
			Total: record.SwapTotal,
			Used:  record.Swap,
		},
		Load: common.LoadReport{
			Load1: float64(record.Load),
		},
		Disk: common.DiskReport{
			Total: record.DiskTotal,
			Used:  record.Disk,
		},
		Network: common.NetworkReport{
			Up:        record.NetOut,
			Down:      record.NetIn,
			TotalUp:   record.NetTotalUp,
			TotalDown: record.NetTotalDown,
		},
		Connections: common.ConnectionsReport{
			TCP: tcpConnections,
			UDP: record.ConnectionsUdp,
		},
		Process:   record.Process,
		UpdatedAt: record.Time.ToTime(),
	}, nil
}
