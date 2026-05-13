<?
$fieldImpl = "";
$arr = array();
for ($i=1; $i <= 23; $i++) { 
    $arr[] = "a$i";
}
$fieldImpl = implode(',',$arr);
$contracts = $conx->query("SELECT id, $fieldImpl FROM contracts WHERE id = '$contractId'")->fetch_array();


$buyer_name    = $contracts['a3']  ?? '';
$buyer_address = $contracts['a11'] ?? '';
$contract_date = $contracts['a2']  ?? '';
?>

<div style="direction:rtl; font-family:cairo; font-size:11px; padding:0 10px; line-height:1.9;">

    <!-- عنوان العقد -->
    <p style="text-align:center; font-size:15px; font-weight:bold; margin-bottom:14px;">عقد صيانة</p>

    <!-- المقدمة -->
    <p>إنه في يوم الخميس الموافق <?= $contract_date ?> م تم الإتفاق فيما بين :</p>

    <!-- الطرف الأول -->
    <p style="margin-top:8px;">أولاً : إلى الفاضل : <?= $buyer_name ?></p>
    <p>العنوان: <?= $buyer_address ?></p>
    <p>تليفون: 30333342</p>
    <p style="margin-bottom:20px;">- طرف أول</p>

    <!-- الطرف الثاني -->
    <p style="margin-top:8px;">ثانياً : السادة/ شركة دلتا لتكنولوجيا المصاعد ذ.م.م</p>
    <p>ويمثلها: المهندس/ محمد رأفت</p>
    <p>الدوحة - قطر</p>
    <p>تليفون: 77710600</p>
    <p style="margin-bottom:20px;">- طرف ثاني</p>

    <!-- التمهيد -->
    <p>أن الطرف الثاني بصفته مسؤول صيانة المصعد يقدم للطرف الأول عقد صيانة للمصعد الخاص بهم الكائن بمنطقة <?= $buyer_address ?>.</p>
    <p style="margin-top:6px;">وقد أتفق الطرفان على الشروط التالية:-</p>

    <!-- بند 1 -->
    <p style="text-align:center; font-weight:bold; margin-top:10px;">بند (1)</p>
    <p style="text-align:center;">تعتبر الديباجة المتقدمة ذكرها جزء لا يتجزأ من هذا العقد</p>

    <!-- بند 2 -->
    <p style="text-align:center; font-weight:bold; margin-top:10px;">بند (2)</p>
    <p style="text-align:center;">يقوم الطرف الثاني بصيانة / صيانة عدد (1) مصعد كما هو موضح بالديباجة اعتباراً من بداية تاريخ التعاقد</p>

    <!-- بند 3 -->
    <p style="text-align:center; font-weight:bold; margin-top:10px;">بند (3)</p>
    <p>- يلتزم الطرف الثاني خلال مدة العقد بالأتي:-</p>

    <ol style="padding-right:20px; margin-top:6px;">
        <li style="padding-bottom:5px;">الكشف الدوري مرة كل شهر على جميع أجهزة المصعد.</li>
        <li style="padding-bottom:5px;">تنظيف مختلف الأدوات و المعدات و الأجهزة الخاصة بالمصعد.</li>
        <li style="padding-bottom:5px;">القيام بجميع أعمال الضبط و التحكم و التدقيق اللازمة لحسن سير المصعد.</li>
        <li style="padding-bottom:5px;">تزييت و تشحيم جميع القطع المعرضة للاحتكاك وذلك بتوفير جميع الزيوت و الشحوم و المسحات اللازمة للتشحيم و التنظيف.</li>
        <li style="padding-bottom:5px;">التأكد من أن جميع أجهزة الأمان بالمصاعد تعمل بانتظام.</li>
        <li style="padding-bottom:5px;">إبلاغ المشترك كتابة أو بواسطة المراقب الفني التابع للطرف الثاني في حال وجود أخطاء في كيفية استعمال المصاعد لتفادي الأضرار و المخاطر الناتجة.</li>
        <li style="padding-bottom:5px;">تصليح أي خلل يطرأ على المصعد و إعادته إلى حالته السليمة بمجرد إبلاغ الطرف الثاني بحدوثه، ويكون التصليح مجاناً إلا في حالة كون سبب الخلل سوء الاستعمال، ويتم هذا التصليح خلال جميع ساعات اليوم بموعد مسبق.</li>
        <li style="padding-bottom:5px;">يسلم الطرف الأول جميع تقارير الصيانة الشهرية إلى الطرف الثاني.</li>
        <li style="padding-bottom:5px;">تلبيه الأعطال أي عدد من الأعطال خلال فترة العقد.</li>
    </ol>

    <!-- بند 4 -->
    <p style="text-align:center; font-weight:bold; margin-top:10px;">بند (4)</p>
    <p style="text-align:center;">يلتزم الطرف الثاني بنظافة و تلميع كابينة و أبواب المصاعد.</p>

    <!-- بند 5 -->
    <p style="text-align:center; font-weight:bold; margin-top:10px;">بند (5)</p>
    <p style="text-align:center;">يقر كل من الطرف الأول و الطرف الثاني بأنه أتخذ له محلا مختارا على العنوان المبين قرين إسمه في كل مايتعلق بتبادل المراسلات و الإخطارات بينهما و الخاصة بتنفيذ هذا العقد.</p>

    <!-- بند 6 -->
    <p style="text-align:center; font-weight:bold; margin-top:10px;">بند (6)</p>
    <p style="text-align:center;">يلتزم الطرف الأول بدفع مبلغ (2000) ريال قطري سنوياً للمصعد.</p>
    <p style="text-align:center;">*عقد الصيانه يشمل الصيانة للمصعد + تبديل قطع الغيار*</p>

    <!-- خاتمة -->
    <p style="margin-top:14px;">حرر هذا العقد من نسختين يحتفظ كل طرف بنسخة منه.</p>

    <!-- التوقيعات -->
    <table width="100%" style="margin-top:30px;">
        <tr>
            <td width="50%" style="vertical-align:top;">
                <p><strong>الطرف الأول:</strong></p>
                <p>السيد: <?= $buyer_name ?></p>
                  <p style="margin-top:8px;">التوقيع:
                  <?php
                  if (isset($_GET['sign'])) {
                      $signUrl = "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/Maintenance_Contracts"
                               . "/signature_{$contractId}.png";

                      $signLocal = __DIR__ . '/tmp/sign_' . $contractId . '.png';

                      $context = stream_context_create([
                          'http' => [
                              'timeout' => 10,
                              'ignore_errors' => true,
                          ]
                      ]);

                      $signData = @file_get_contents($signUrl, false, $context);

                      if ($signData !== false && strlen($signData) > 100) {
                          file_put_contents($signLocal, $signData);
                          echo '<img src="' . $signLocal . '" style="width:100px; height:auto;">';
                      } else {
                          echo '_______________';
                      }
                  } else {
                      echo '_______________';
                  }
                  ?>
                  </p>
              
            </td>
            <td width="50%" style="vertical-align:top; text-align:left;">
                <p><strong>الطرف الثاني:</strong></p>
                <p>دلتا لتكنولوجيا المصاعد و التجارة</p>
                <p style="margin-top:8px;">التوقيع: _______________</p>
            </td>
        </tr>
    </table>

</div>