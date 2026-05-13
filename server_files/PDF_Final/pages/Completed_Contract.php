<?
include("../xtras/config.php");
$cont = $conx->query("SELECT bookings.date, bookings.contract_id , addresses.building , addresses.zone , cust_app.a1 FROM bookings LEFT JOIN addresses ON bookings.addressId = addresses.id LEFT JOIN cust_app ON bookings.uid = cust_app.a3 WHERE bookings.id = '$batchId'")->fetch_assoc();
$days = [
    'Saturday'  => 'السبت',
    'Sunday'    => 'الأحد',
    'Monday'    => 'الاثنين',
    'Tuesday'   => 'الثلاثاء',
    'Wednesday' => 'الأربعاء',
    'Thursday'  => 'الخميس',
    'Friday'    => 'الجمعة',
];

$dayName = $days[date('l', strtotime($cont['date']))];
$contractId = $cont['contract_id'];
?>

<div class="content" style="margin:0 43px;">
    <h2 style="text-align:center;">محضر تسليم المصعد</h2>
    <div style="font-weight:bold;">إنه في يوم: <span dir="ltr"><?=$cont['date'];?></span> الموافق: <span><?=$dayName;?></span></div>
    <br>
    <div>
        <table width="100%" style="border-collapse:collapse;">
            <tr>
            <td width="70%" style="padding:8px; text-align:right;">
                <div style="font-weight:bold;">تم تسليم المصعد بمشروع: </div>
                <br>
                <div style="font-weight:bold;">مبنى رقم <?=$cont['building'];?></div>
            </td>
            <td width="30%" style="padding:8px; text-align:right;">
                <div style="font-weight:bold;">الكائن في:</div>
                <br>
                <div style="font-weight:bold;">المنطقة رقم <?=$cont['zone'];?></div>
            </td>
            </tr>
        </table>
    </div>
    <br>
    <div>
        <table width="100%" style="border-collapse:collapse;">
            <tr>
            <td width="70%" style="padding:8px; text-align:right;">
                <div style="font-weight:bold;">من شركة</div>
                <br>
                <div style="font-weight:bold;">دلتا لتكنولوجيا المصاعد والتجارة ذ.م.م</div>
            </td>
            <td width="30%" style="padding:8px; text-align:right;">
                <div style="font-weight:bold;">إلى السيد / السادة:</div>
                <br>
                <div style="font-weight:bold;"><?=$cont['a1'];?></div>
            </td>
            </tr>
        </table>
    </div>
    <div style="font-weight:bold;text-align:center;">-------------------</div>
    <div style="font-weight:bold;">يقر الطرف المستلم بأنه قد استلم المصعد المذكور أعلاه بحالة جيدة وصالحة للتشغيل , بعد الفحص والتجربة.</div>
    <div style="font-weight:bold;">كما يقر بأن المصعد يعمل بصورة طبيعية , وأنه لا توجد لديه أي ملاحظات وقت الاستلام</div>
    <div style="font-weight:bold;text-align:center;">-------------------</div>
    <h4 style="font-weight:bold;">التوقيعات</h4>
    <div>
        <table width="100%" style="border-collapse:collapse;">
            <tr>
            <td width="70%" style="padding:8px; text-align:right;">
                <div style="font-weight:bold;">الطرف الأول (الشركة)</div>
                <br>
                <div style="font-weight:bold;">الإسم: دلتا لتكنولوجيا المصاعد والتجارة ذ.م.م</div>
                <br>
                <div style="font-weight:bold;">التوقيع: </div>
            </td>
            <td width="30%" style="padding:8px; text-align:right;">
                <div style="font-weight:bold;">الطرف الثاني (العميل):</div>
                <br>
                <div style="font-weight:bold;">الإسم: <?=$cont['a1'];?></div>
                <br>
                <div style="font-weight:bold;">التوقيع: </div>
                <br>
            </td>
            </tr>
        </table>
        <div style="text-align:left;"><img src="https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/IIP_Contracts/signature_<?=$contractId;?>.png" alt="" width="80px"></div>
    </div>
    <h4 style="font-weight:bold;">ختم الشركة</h4>

</div> 

