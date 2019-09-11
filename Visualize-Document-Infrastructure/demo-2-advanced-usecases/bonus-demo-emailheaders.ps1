$Header = @"
Received: from SN4PR0401MB3614.namprd04.prod.outlook.com (2603:10b6:207:18::37) by MN2PR04MB6238.namprd04.prod.outlook.com with HTTPS via BL0PR0102CA0024.PROD.EXCHANGELABS.COM; Tue, 13 Aug 2019 11:04:28 +0000
Received: from CO2PR04CA0147.namprd04.prod.outlook.com (2603:10b6:104::25) by SN4PR0401MB3614.namprd04.prod.outlook.com (2603:10b6:803:4b::19) with Microsoft SMTP Server (version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 15.20.2157.14; Tue, 13 Aug 2019 11:04:26 +0000
Received: from CO1NAM05FT015.eop-nam05.prod.protection.outlook.com (2a01:111:f400:7e50::203) by CO2PR04CA0147.outlook.office365.com (2603:10b6:104::25) with Microsoft SMTP Server (version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384) id 15.20.2157.14 via Frontend Transport; Tue, 13 Aug 2019 11:04:25 +0000
 Authentication-Results: spf=pass (sender IP is 46.137.118.255)
 smtp.mailfrom=webrootanywhere.com; test.com; dkim=none (message not
 signed) header.d=none;test.com; dmarc=bestguesspass action=none
 header.from=webrootanywhere.com;compauth=pass reason=109
Received-SPF: Pass (protection.outlook.com: domain of webrootanywhere.com designates 46.137.118.255 as permitted sender) receiver=protection.outlook.com; client-ip=46.137.118.255;
 helo=skymail.webrootcloudav.com;
Received: from skymail.webrootcloudav.com (46.137.118.255) by CO1NAM05FT015.mail.protection.outlook.com (10.152.96.122) with Microsoft SMTP Server id 15.20.2178.6 via Frontend Transport; Tue, 13 Aug 2019 11:04:18 +0000
Received: from ip-0A089AFE ([127.0.0.1]) by skymail.webrootcloudav.com with Microsoft SMTPSVC(7.0.6002.18264);	 Tue, 13 Aug 2019 11:04:16 +0000
MIME-Version: 1.0
From: "Webroot Support" <wrcstickets@webrootanywhere.com>
To: prateek@test.com
Date: 13 Aug 2019 11:04:16 +0000
Subject: [EXTERNAL] New Webroot support ticket (#264277)
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: base64
Return-Path: wrcstickets@webrootanywhere.com
Message-ID: <IP-0A089AFER1Cm7yvg001041be@skymail.webrootcloudav.com>
X-OriginalArrivalTime: 13 Aug 2019 11:04:16.0928 (UTC) FILETIME=[D95AD200:01D551C6]
X-MS-Exchange-Organization-ExpirationStartTime: 13 Aug 2019 11:04:18.3060
 (UTC)
X-MS-Exchange-Organization-ExpirationStartTimeReason: OriginalSubmit
X-MS-Exchange-Organization-ExpirationInterval: 1:00:00:00.0000000
X-MS-Exchange-Organization-ExpirationIntervalReason: OriginalSubmit
X-MS-Exchange-Organization-Network-Message-Id:
 67f2affa-0bb0-47ac-17dc-08d71fddfca4
X-EOPAttributedMessage: 0
X-EOPTenantAttributedMessage: c40ed5d6-e0e3-4d79-830c-7991f33a7c8e:0
X-MS-Exchange-Organization-MessageDirectionality: Incoming
X-Forefront-Antispam-Report:
 CIP:46.137.118.255;IPV:NLI;CTRY:IE;EFV:NLI;SFV:NSPM;SFS:(4636009)(286005)(199004)(189003)(8156004)(356004)(4744005)(436003)(34206002)(10126004)(336012)(450100002)(86362001)(26005)(7126003)(1096003)(2351001)(66574012)(476003)(2361001)(9686003)(6306002)(486006)(15003)(966005)(52146003)(50466002)(23676004)(2486003)(8676002)(106002)(126002)(305945005)(18074004)(5024004)(81156014)(81166006)(7416002)(7406005)(14444005)(47776003)(42522002);DIR:INB;SFP:;SCL:1;SRVR:SN4PR0401MB3614;H:skymail.webrootcloudav.com;FPR:;SPF:Pass;LANG:en;PTR:skymail1.webrootanywhere.com;A:1;MX:1;
X-MS-Exchange-Organization-AuthSource:
 CO1NAM05FT015.eop-nam05.prod.protection.outlook.com
X-MS-Exchange-Organization-AuthAs: Anonymous
X-MS-PublicTrafficType: Email
X-MS-Office365-Filtering-Correlation-Id: 67f2affa-0bb0-47ac-17dc-08d71fddfca4
X-Microsoft-Antispam:
 BCL:1;PCL:0;RULEID:(2390118)(7020095)(4652040)(5600148)(711020)(4605104)(4709080)(1414054)(71702078);SRVR:SN4PR0401MB3614;
X-MS-TrafficTypeDiagnostic: SN4PR0401MB3614:
X-MS-Exchange-PUrlCount: 1
X-MS-Exchange-AtpMessageProperties: SA|SL
X-MS-Exchange-Transport-Forked: True
X-MS-Oob-TLC-OOBClassifiers: OLM:7691;
X-MS-Exchange-Organization-SCL: 1
X-MS-Exchange-Safelinks-Url-KeyVer: 1
X-MS-Exchange-ATPSafeLinks-Stat: 0
X-Auto-Response-Suppress: DR, OOF, AutoReply
X-MS-Exchange-CrossTenant-OriginalArrivalTime: 13 Aug 2019 11:04:17.8046
 (UTC)
X-MS-Exchange-CrossTenant-Network-Message-Id: 67f2affa-0bb0-47ac-17dc-08d71fddfca4
X-MS-Exchange-CrossTenant-Id: c40ed5d6-e0e3-4d79-830c-7991f33a7c8e
X-MS-Exchange-CrossTenant-FromEntityHeader: Internet
X-MS-Exchange-Transport-CrossTenantHeadersStamped: SN4PR0401MB3614
X-MS-Exchange-Transport-EndToEndLatency: 00:00:02.8914138
X-MS-Exchange-Processed-By-BccFoldering: 15.20.2157.000
X-Microsoft-Antispam-Mailbox-Delivery:
	ucf:0;jmr:0;ex:0;auth:0;dest:I;ENG:(20160514016)(750119)(520011016);
X-Microsoft-Antispam-Message-Info:
	=?us-ascii?Q?ZiXnhlYwumJpwMeECCc6B/qpLtZF9/aEnuhPmM7XLsvD0UdH1DV22KxMuFCH?=
 =?us-ascii?Q?D+2JNwMFrb0yuL1yjZJt1DRuXrnBh7VLqQhtuzh7TJqP2/NW/OSDUFpV5YmH?=
 =?us-ascii?Q?5bT8PIVelFWRlCICARJnV9ybW7KGEUYjP2x8veoO9IX7p57L8R98ymFVhfOV?=
 =?us-ascii?Q?UKJw31loqS9ouBCVHJcXshwtb1tHDId496OD4SEPIToU29XySf3P7HUsNiBv?=
 =?us-ascii?Q?ybdTMP2rFNQFFu4lkj3OVE1yWYMmxOHwGP2mwj3xm1xBgH3lKmUmRc8AVRQV?=
 =?us-ascii?Q?T6n9/f6JonW7ff2CdF0QbP2iah0TeQZyG59oBb6W/DMSY0lveS7wAaT6o6+J?=
 =?us-ascii?Q?4hcYLGNO93Hk2sx/uzYDup4kawRhkPTmPB5vhRFWHbef2G22tOGMkH/fIKGH?=
 =?us-ascii?Q?vM+V8VUs750eCheqXJnIuBNV82T2Slnve9EWgc25o5O1/45YfhpYtULNnNXI?=
 =?us-ascii?Q?KKktOYtrpAwFqroN06+BxYG/bbtnBdceS/XkcGtuOrffRK+ByXk843zWjZGg?=
 =?us-ascii?Q?/WXBAA9POYNSRxO3pFd2iamkYI60jb/RvnR33vd7TdMkMsraugcDVY7qI+Zn?=
 =?us-ascii?Q?ipnAVI1QqeXDwDqgl3VcnLekjFsv4JPIvZzlrJuuhm8uH99Apj04vLH1xEGi?=
 =?us-ascii?Q?tUSN+DYvHa7is0GNy2ZFlSQY+eC1iedFhPaU8t43nzopSu2P0sgG8Le1GwQT?=
 =?us-ascii?Q?6AiwQQw8eiM74CCcOlpe5CPVGsl1vwxcf5R5Ha68AnontPxOeZ7zCvhG3kxM?=
 =?us-ascii?Q?m/oXZwzVBqL+BGaOnoKv4eWobZZv3eC4JnoM7vWeczj9CKRw9+ihXQcu+uyn?=
 =?us-ascii?Q?+Uq+8k4Owu/pyeCohSmxSVOppvsnugdGoj7C5lCnAERJxjh0PByIg/OsViu0?=
 =?us-ascii?Q?38VNPcuM9yAMH3QyO3GsJ9VwDsxBgSVQ4nEXz1bhCOqcwue6A8hOLVugUSet?=
 =?us-ascii?Q?/4gvMmsWWN8XXTQt/cOFv77wsL/g364e3y9J3aRCmjWzZQbv8QukLOJz+71x?=
 =?us-ascii?Q?nqsw+cW56Z2YTQXpwxtJbfhsXNADCRnLQn6JF7Pe6bRFxBIU1Z2TiDtHV3yA?=
 =?us-ascii?Q?2wSn+vn1XUkGLL5Cg37IEfiEzBHkkC8dSA95qyDk4aZWwfPONIX0cs/vZuPY?=
 =?us-ascii?Q?nasvcxx8ehmcW3nU7ky6Dgw+GjvaSxJIM8IJvOQxzphw+O0J9YA8ML7vit3l?=
 =?us-ascii?Q?iZFEsnSzHViHk5tKzPYfWNebrQIz3MsSqX4JKPp6ssEMo056JLh7E0arPzQ?=
 =?us-ascii?Q?=3D?=
"@

Function ConvertFrom-EmailHeader {
    Param($Header)
    $Pattern = 'Received: from([\s\S]*?)by([\s\S]*?)with([\s\S]*?);([(\s\S)*]{32,36})(?:\s\S*?)'
    $Matches = $Header | Select-String -Pattern $Pattern -AllMatches
    $MatchFound = $Matches.Matches
    if ($MatchFound) {
        For ($i = 0; $i -lt $MatchFound.count; $i++) {
            # $fromMatches.Matches | ForEach-Object {
            $from = $MatchFound[$i].groups[1].value.trim()
            $by = $MatchFound[$i].groups[2].value.trim()
            $with = $MatchFound[$i].groups[3].value.trim()
            Switch -wildcard ($with) {
                "*HTTP*" { $with = "HTTP" }
                "*SMTP*" { $with = "SMTP" }
                "*ESMTP*" { $with = "ESMTP" }
                default { }
            }
            $time = $MatchFound[$i].groups[4].value.trim()
            # try {
            #     if ($i -eq 0) {
            #         $timenext = $time
            #     }
            #     else {
            #         $timenext = $MatchFound[$i + 1].groups[4].value.trim()
            #     }
            # }
            # catch {

            # }
            
            $fromHost, $fromIP = $from.Split(' ').Replace('(', '').Replace(')', '').Replace('[', '').Replace(']', '').trim()
            $ByHost, $ByIP = $By.Split(' ').Replace('(', '').Replace(')', '').Replace('[', '').Replace(']', '').trim()

            [PSCustomObject] @{
                ReceivedFromFrom   = $fromHost
                ReceivedFromFromIP = $fromIP
                ReceivedFromBy     = $byHost
                ReceivedFromByIP   = if ($byIP) { $byIP }else { ' ' }
                Protocol           = $with
                ReceivedFromTime   = [Datetime]$time
                Delay              = ''
            }                               
        }
    }
    else {
        return $null
    }
}

$threshold = 1
$data = ConvertFrom-EmailHeader $Header | Sort-Object ReceivedFromTime 
graph @{overlap = 'false'; splines = 'true'; label="Email Relay Route";} {
    Node @{Shape = 'rectangle' }
    $data[0].'Delay' = '0 Sec'
    For ($i = 0; $i -lt $data.count; $i++) {
        try {
            $relay = 0
            if ($i -ne 0) {
                $relay = (([datetime]($data[$i + 1]).ReceivedFromTime) - ([datetime]($data[$i]).ReceivedFromTime)).totalseconds
            }
            $data[$i + 1].'Delay' = if ($relay) { "$relay sec" }else { '0 sec' }
        }
        catch {
            # do nothing
        }        
        
        if ($data[$i].Delay.split(' ')[0] -gt $threshold) {
            $bgcolor = 'indianred1'
        }
        else {
            $bgcolor = 'limegreen'
        }
        Node -Name $data[$i].ReceivedFromFrom @{
            style = "filled";
            color = $bgcolor
        }
        Record -Name $data[$i].ReceivedFromFrom {
            Row -Label "<b>From IP   :</b> <i>$($data[$i].ReceivedFromFromIP)</i>"
            Row -Label "<b>By        :</b> <i>$($data[$i].ReceivedFromBy)</i>"
            Row -Label "<b>By IP     :</b> <i>$($data[$i].ReceivedFromByIP)</i>"
            Row -Label "<b>Protocol  :</b> <i>$($data[$i].Protocol)</i>"
            Row -Label "<b>Time      :</b> <i>$($data[$i].ReceivedFromTime)</i>"
            "<TR><TD ALIGN=`"LEFT`" bgcolor=`"$bgcolor`"><b>Delay     :</b> <i>$($data[$i].Delay)</i></TD></TR>"
            # Row -Label "<b>Delay     :</b> <i>$($data[$i].Delay)</i>"
        }
        "`"$($data[$i].ReceivedFromFrom)`" [label=<<TABLE CELLBORDER=`"1`" BORDER=`"0`" CELLSPACING=`"0`"><TR><TD bgcolor=`"black`" align=`"center`"><font color=`"white`"><B>$($data[$i].ReceivedFromFrom)</B></font></TD></TR><TR><TD ALIGN=`"LEFT`"><b>From IP   :</b> <i>$($data[$i].ReceivedFromFromIP)</i></TD></TR><TR><TD PORT=`"f31272bb-1f45-4965-93c7-1daca990e674`" ALIGN=`"LEFT`"><b>By        :</b> <i>$($data[$i].ReceivedFromBy)</i></TD></TR><TR><TD PORT=`"530dc490-81cb-41b6-b16e-f549e0cfd70f`" ALIGN=`"LEFT`"><b>By IP     :</b> <i>$($data[$i].ReceivedFromByIP)</i></TD></TR><TR><TD PORT=`"aa5ca488-9226-441a-bdba-34cc6a943a84`" ALIGN=`"LEFT`"><b>Protocol  :</b> <i>$($data[$i].Protocol)</i></TD></TR><TR><TD PORT=`"3792afe2-e31f-4907-a982-a34a650046f1`" ALIGN=`"LEFT`"><b>Time      :</b> <i>$($data[$i].ReceivedFromTime)</i></TD></TR><TR><TD ALIGN=`"LEFT`" PORT=`"3792afe2-e31f-4907-a982-a34a650046d1`" bgcolor=`"$bgcolor`"> <b>Delay     :</b> <i>$($data[$i].Delay)</i></TD></TR></TABLE>>;fillcolor=`"white`";shape=`"none`";style=`"filled`";penwidth=`"1`";fontname=`"Courier New`";]"
        
        edge -from $data[$i].ReceivedFromFrom -to $data[$i + 1].ReceivedFromFrom  @{Label = " Relay-$($i+1)" }
    }
} | Export-PSGraph