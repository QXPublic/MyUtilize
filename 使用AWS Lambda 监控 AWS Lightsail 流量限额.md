一、主要实现方式如下：
利用Amazon的Lambda函数计算（每月100W次以内免费），配合Amazon提供的官方Lightsail API，设置定时任务，每10分钟获取当前流量限额和已使用流量，进行对比，如果达到限额的95%，则关闭Lightsail实例：

1、利用 Lightsail 的 API 接口：get_instance，获取账号下在当前区域里的所有 Lightsail 实例。
2、根据 Lightsail 实例的类型，获取每个实例每个月的网络流量配额。
3、根据实例的创建时间，计算出每个实例在当前这个计费周期内的流量配额。
4、通过 API 接口：get_instance_metric_data，获取每个实例已经使用的入站和出站流量总量。
5、如果流量超出当前计费周期的配额，则通过 SNS 发送提醒邮件，并关闭对应的 Lightsail 实例。
6、通过 EventBridge 以 cron job 的方式定时触发 Lambda，运行此检查逻辑。

二、过程
1. 创建Lambda函数
在AWS控制台进入Lambda函数页面，创建新函数：

![](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2018:32:52.jpg?raw=true)
![](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2018%3A33%3A07.jpg)

Python脚本：
``` 
import boto3
import os
import requests
from datetime import datetime, date, time, timedelta

# --- 配置区域 ---
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# 请在这里手动填入您的 Telegram Bot Token 和 Chat ID
TELEGRAM_BOT_TOKEN = 'Telegram Bot Token'  # 例如: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11'
TELEGRAM_CHAT_ID = 'Chat ID' # 例如: '123456789' 或 '@your_channel_name'

# 可选项 (如果不需要，可以保持默认值)
QUOTA_PERCENT = 95.0  # 关机阈值，95.0 代表使用量达到 95% 时关机
INSTANCES_TO_MONITOR = 'ALL' # 要监控的实例名，用逗号分隔，例如 "Debian-1,Debian-2"。填 'ALL' 代表监控所有实例。
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# --- 辅助函数 ---

def bytes_to_billing_gb(byte_value):
    """
    将字节转换为GB（基于1000），与 AWS Lightsail 计费标准保持一致。
    """
    if byte_value is None or byte_value == 0:
        return 0.0
    # AWS Lightsail 流量配额基于 1000 的幂 (GB)，而不是 1024 (GiB)
    return byte_value / (1000**3)

def send_to_telegram(message):
    """发送消息到 Telegram"""
    if not TELEGRAM_BOT_TOKEN or 'YOUR' in TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID or 'YOUR' in TELEGRAM_CHAT_ID:
        print("Telegram BOT_TOKEN 或 CHAT_ID 未配置。跳过通知。")
        return

    api_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': message,
        'parse_mode': 'Markdown' # 允许加粗等格式
    }
    try:
        response = requests.post(api_url, json=payload, timeout=10)
        response.raise_for_status()
        print("成功发送消息到 Telegram。")
    except requests.exceptions.RequestException as e:
        print(f"发送 Telegram 消息失败: {e}")

def get_all_lightsail_instances(lightsail_client):
    """获取所有 Lightsail 实例的详细信息，使用分页器处理"""
    all_instances = []
    try:
        paginator = lightsail_client.get_paginator('get_instances')
        pages = paginator.paginate()
        for page in pages:
            all_instances.extend(page['instances'])
    except Exception as e:
        print(f"获取 Lightsail 实例列表时出错: {e}")
    return all_instances

def get_instance_metrics(lightsail_client, instance_name):
    """获取实例当月的流入和流出总流量（字节）"""
    today = datetime.utcnow().date()
    start_of_month = datetime(today.year, today.month, 1)
    
    total_usage = {'NetworkIn': 0, 'NetworkOut': 0}
    
    for metric_name in ['NetworkIn', 'NetworkOut']:
        try:
            response = lightsail_client.get_instance_metric_data(
                instanceName=instance_name,
                metricName=metric_name,
                period=86400, # 每天一个数据点
                startTime=start_of_month,
                endTime=datetime.utcnow(),
                unit='Bytes',
                statistics=['Sum']
            )
            metric_sum = sum(dp.get('sum', 0) for dp in response.get('metricData', []))
            total_usage[metric_name] = metric_sum
        except Exception as e:
            print(f"获取实例 '{instance_name}' 的 '{metric_name}' 指标时出错: {e}")

    return total_usage

def calculate_prorated_quota(instance):
    """
    计算实例的当月配额。如果实例是本月创建的，则按比例折算配额。
    """
    full_quota_gb = instance['networking']['monthlyTransfer']['gbPerMonthAllocated']
    created_at = instance['createdAt']
    now = datetime.now(created_at.tzinfo) 

    if created_at.year == now.year and created_at.month == now.month:
        first_day_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        next_month = first_day_of_month.replace(day=28) + timedelta(days=4)
        last_day_of_month = next_month - timedelta(days=next_month.day)
        end_of_month = last_day_of_month.replace(hour=23, minute=59, second=59, microsecond=999999)

        total_seconds_in_month = (end_of_month - first_day_of_month).total_seconds()
        valid_seconds_for_instance = (end_of_month - created_at).total_seconds()
        
        prorated_quota_gb = (valid_seconds_for_instance / total_seconds_in_month) * full_quota_gb
        print(f"实例 '{instance['name']}' 于本月创建，配额已折算: {prorated_quota_gb:.2f} GB")
        return prorated_quota_gb
    else:
        print(f"实例 '{instance['name']}' 享受完整月度配额: {full_quota_gb} GB")
        return full_quota_gb


# --- 核心处理逻辑 ---

def handle_instance_check_and_shutdown():
    """高频检查任务：检查流量，如果超标则关机并通知"""
    print("模式: 检查并关机")
    lightsail_client = boto3.client('lightsail')
    all_instances = get_all_lightsail_instances(lightsail_client)
    
    if not all_instances:
        print("未找到任何 Lightsail 实例。")
        return

    monitor_list = [s.strip() for s in INSTANCES_TO_MONITOR.split(',')]
    instances_to_process = all_instances
    if 'ALL' not in monitor_list:
        instances_to_process = [inst for inst in all_instances if inst['name'] in monitor_list]

    for instance in instances_to_process:
        instance_name = instance['name']
        
        if instance['state']['name'] != 'running':
            print(f"实例 '{instance_name}' 当前状态为 {instance['state']['name']}，跳过检查。")
            continue

        print(f"\n--- 正在处理实例: {instance_name} ---")
        quota_gb = calculate_prorated_quota(instance)
        # 将 GB 配额转换为字节进行比较，必须使用 1000 作为基数
        quota_bytes = quota_gb * (1000**3)
        usage_metrics = get_instance_metrics(lightsail_client, instance_name)
        total_usage_bytes = usage_metrics['NetworkIn'] + usage_metrics['NetworkOut']
        
        usage_percent = (total_usage_bytes / quota_bytes * 100) if quota_bytes > 0 else 0
        
        summary_message = (
            f"实例名称: {instance_name}\n"
            f"已用流量: {total_usage_bytes:,.0f} B ({bytes_to_billing_gb(total_usage_bytes):.2f} GB)\n"
            f"每月配额: {quota_bytes:,.0f} B ({quota_gb:.2f} GB)\n"
            f"使用比例: {usage_percent:.2f}%"
        )
        print(summary_message)
        
        shutdown_threshold = QUOTA_PERCENT / 100.0
        if total_usage_bytes >= (quota_bytes * shutdown_threshold):
            print(f"警告! 实例 '{instance_name}' 流量使用已达到 {usage_percent:.2f}%，超过 {QUOTA_PERCENT}% 的阈值。")
            try:
                print(f"正在尝试关停实例 '{instance_name}'...")
                lightsail_client.stop_instance(instanceName=instance_name)
                final_message = f"🚨 *Lightsail 流量超额警告* 🚨\n\n{summary_message}\n\n*操作: 已成功发送关机指令！*"
                send_to_telegram(final_message)
            except Exception as e:
                print(f"关停实例 '{instance_name}' 失败: {e}")
                final_message = f"🚨 *Lightsail 流量超额警告* 🚨\n\n{summary_message}\n\n*操作: 关机指令发送失败！请手动检查！*\n错误: {e}"
                send_to_telegram(final_message)
        else:
            print(f"实例 '{instance_name}' 流量正常。")


def handle_daily_report():
    """每日报告任务：发送所有受监控实例的流量使用情况"""
    print("模式: 生成每日报告")
    lightsail_client = boto3.client('lightsail')
    all_instances = get_all_lightsail_instances(lightsail_client)
    
    if not all_instances:
        send_to_telegram("📊 *Lightsail 每日流量报告*\n\n未在您的账户中找到任何 Lightsail 实例。")
        return

    monitor_list = [s.strip() for s in INSTANCES_TO_MONITOR.split(',')]
    instances_to_process = all_instances
    if 'ALL' not in monitor_list:
        instances_to_process = [inst for inst in all_instances if inst['name'] in monitor_list]

    report_parts = [f"📊 *Lightsail 每日流量报告* ({datetime.now().strftime('%Y-%m-%d')})\n"]
    
    for instance in instances_to_process:
        instance_name = instance['name']
        print(f"\n--- 正在为报告收集实例信息: {instance_name} ---")
        
        quota_gb = calculate_prorated_quota(instance)
        # 将 GB 配额转换为字节，基数为 1000
        quota_bytes = quota_gb * (1000**3)
        usage_metrics = get_instance_metrics(lightsail_client, instance_name)
        total_usage_bytes = usage_metrics['NetworkIn'] + usage_metrics['NetworkOut']
        
        usage_percent = (total_usage_bytes / quota_bytes * 100) if quota_bytes > 0 else 0
        instance_summary = (
            f"\n------------------------------------\n"
            f"*实例名称: {instance_name}*\n"
            f"状态: {instance['state']['name']}\n"
            f"已用流量: {bytes_to_billing_gb(total_usage_bytes):.2f} GB\n"
            f"每月配额: {quota_gb:.2f} GB\n"
            f"使用比例: {usage_percent:.2f}%"
        )
        report_parts.append(instance_summary)

    full_report = "".join(report_parts)
    print("--- 最终报告 ---")
    print(full_report)
    send_to_telegram(full_report)


# --- Lambda 主入口 ---

def lambda_handler(event, context):
    """
    根据触发事件的类型，决定执行哪个任务。
    - 如果事件中包含 'report_type':'daily_report'，则发送日报。
    - 否则，执行高频的检查与关机任务（这是默认行为）。
    """
    if event.get('report_type') == 'daily_report':
        handle_daily_report()
    else:
        handle_instance_check_and_shutdown()
    
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda function executed successfully!')
    }
```
2. 修改函数运行配置
在之前创建的Lambda函数页面，进入配置——常规配置——编辑：
![](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2018%3A53%3A29.jpg)

调大内存和超时时间：
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2018%3A53%3A33.jpg)

3. 赋予Lambda权限
在之前创建的Lambda函数页面，进入配置——权限——点击链接跳转至IAM权限管理页面：
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2018%3A57%3A38.jpg)

创建新的策略：
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2018%3A57%3A41.jpg)

选择JSON，粘贴数据，保存:
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2019%3A00%3A16.jpg)

JSON数据：
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "lightsail:GetInstance",
                "lightsail:GetInstanceMetricData",
                "lightsail:GetInstances",
                "lightsail:StopInstance"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```
策略创建完成后关闭IAM权限页面，回到Lambda函数页面，测试是否成功：
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2019%3A03%3A44.jpg)

4. 创建定时任务触发Lambda函数
在Lambda函数页面点击配置触发器 1：选择EventBridge，增加定时任务，保存：

表达式：```cron(0/10 * * * ? *)```
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2019%3A03%3A46.jpg)

配置触发器 2：每日tg定时发送流量报告：
这是用来在每天固定时间发送总结报告的触发器。

再次点击 Add trigger (添加触发器)。
1、选择 EventBridge (CloudWatch Events)。
2、选择 Create a new rule (创建新规则)。
3、Rule name (规则名称): Lightsail_Daily_Report
4、Rule type (规则类型): 选择 Schedule expression (计划表达式)。
Schedule expression (计划表达式):
这里需要使用 Cron 表达式。注意：AWS 的 Cron 表达式使用 UTC 时间。
如果想在北京时间每天 23:58 发送，那么对应的 UTC 时间是 15:58。表达式为：```cron(58 15 * * ? *)```

向下滚动到 Target input (目标输入) 或 Configure input 部分。
选择 Constant (JSON text)。
在下方的文本框中，输入以下内容：
```{
  "report_type": "daily_report"
}```

5. 查看历史执行记录
在Lambda函数页面，选择监控，点击查看CloudWatch Logs跳转至日志页面。
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2019%3A07%3A15.jpg)

选择日志就可以看到日志的详细信息以及历史执行结果：
![ ](https://github.com/QXPublic/MyUtilize/blob/main/%E4%BD%BF%E7%94%A8AWS%20Lambda%20%E7%9B%91%E6%8E%A7%20AWS%20Lightsail%20%E6%B5%81%E9%87%8F%E9%99%90%E9%A2%9D.assets/IMAGE%202025-10-26%2019%3A07%3A19.jpg)


四、参考资料
[【教程】使用AWS Lambda 监控 AWS Lightsail 流量限额，超额自动关机](https://www.nodeseek.com/post-73756-1)








