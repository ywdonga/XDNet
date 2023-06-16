#  更新日志

## 0.2.2 (2022-08-15)
1. 增加单次请求是否启用日志开关`enableLog`，默认false，即不开启；此配置优先级低于`Network.isEnableLog`开关, 如果全局未开启日志，此参数配置无效
2. 修改最低系统兼容性为iOS 11
3. 修复检查重复请求可能出现数据竞态的问题

## 0.2.1 (2022-04-28)
1. 增加`Network.isEnableRepeatRequestCheck`设置，是否开启重复网络请求检查，默认true
2. 优化请求出错处理逻辑

## 0.2.0 (2022-04-26)
1.  `protocol CachableTarget` 增加`remitRepeatCheck`  用于豁免请求判断重复的处理
2.  增加`KFErroe.noResultFieldError` 状态码为`KF1000` 用于接口返回数据无result字段或者result字段为null的场景
3. 重构了内部判断重复请求类`RepeatRequestChecker`的实现逻辑
4. 增加量子力学类`SchrodingersCat<Live,Dead>`枚举类型, 用于解决某个字段可能出现两种不同类型的值, 遵循Codale协议, HandyJSON无此问题
	```json
	// 返回值1
	{
		"status": "C0000",
		"result": 12
	}
	// 返回值2
	{
		"status": "C0000",
		"result": "123"
	}

	// 以上可用以下方式处理
	let model: SchrodingersCat<Int, String> = ...
	model值为 .live(12) 或 .dead("123")
	```
