<?
include("../xtras/config.php");
$fieldImpl = "";

$userCont = $conx->query("SELECT cust_app.a1 , cust_app.a2 FROM bookings LEFT JOIN cust_app ON bookings.uid = cust_app.a3 WHERE bookings.contract_id = '$contractId'")->fetch_array();

$bookCont = $conx->query("SELECT items.a4, bookings.orderId FROM bookings LEFT JOIN orders ON bookings.orderId = orders.oid LEFT JOIN items ON orders.itmid = items.id WHERE bookings.contract_id = '$contractId'")->fetch_array();

$oid = $bookCont[1];

$arr = array();
for ($i=1; $i <= 23; $i++) { 
    $arr[] = "a$i";
}

$arrLifts = array();
for ($i=1; $i <= 24; $i++) { 
    $arrLifts[] = "a$i";
}

$fieldImpl = implode(',',$arr);
$contracts = $conx->query("SELECT id, $fieldImpl FROM contracts WHERE id = '$contractId'")->fetch_array();
$client_adress = $conx->query("SELECT bookings.contract_id , addresses.city FROM bookings LEFT JOIN addresses ON bookings.addressId = addresses.id WHERE bookings.contract_id = '$contractId'")->fetch_array();

$lift_id = $contracts['a7'];

$lblxArr = array();
$liftsLabels = $conx->query("SELECT arb FROM labels WHERE typex = 'lifts'");
while($rows = mysqli_fetch_array($liftsLabels)){
    $lblxArr[] = $rows;
}

$itmxArr = array();
$itemsSqlx = $conx->query("SELECT orders.itmid , items.a1 , items.a2 , items.a3 FROM orders LEFT JOIN items ON orders.itmid = items.id WHERE orders.oid = '$oid'");
while($rows = mysqli_fetch_array($itemsSqlx)){
    $itmxArr[] = $rows;
}




$columns = array();
$labelsCount = count($lblxArr);
for($i = 1; $i <= $labelsCount; $i++){
    $columns[] = "a" . $i;
}
$columnsStr = implode(", ", $columns);

// جلب بيانات المصعد المحدد
$liftData = array();
    $liftQuery = $conx->query("SELECT id, " . $columnsStr . " FROM lifts WHERE id = '$lift_id'");
    if($liftQuery && mysqli_num_rows($liftQuery) > 0){
        $liftData = mysqli_fetch_assoc($liftQuery);
    }

$persons = $lift_det['a7'] ?? 0;
$weight_per_person = 75;
$total_weight = $persons * $weight_per_person;

$lftxarr = array();
$lftxQuery = "SELECT a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16 FROM lifts WHERE id = '".$bookCont[0]."'";
$lftxResult = $conx->query($lftxQuery);
while($rows=mysqli_fetch_assoc($lftxResult)) {$lftxarr[] = $rows;}

$contract_num   = $contracts[0]  ?? '10102024';
$contract_date  = $contracts['a2']  ?? '01-03-2024';
$buyer_name     = $userCont[0]  ?? 'محمد عبد الخالق عبدالله الغامدى';
$buyer_phone    = $userCont[1];
$buyer_address  = $client_adress[1] ?? 'الوكير';
$buyer_id       = $contracts['a23'] ?? '';
$price          = $contracts['a15'] ?? '70000';
$pay1           = number_format($contracts['a16'] ?? 35000);
$pay2           = number_format($contracts['a17'] ?? 28000);
$pay3           = number_format($contracts['a18'] ?? 7000);
$contract_type  = 'عقد تركيب و توريد مصعد ركاب فوجي';
?>

<div style="direction:rtl; font-family:cairo; font-size:11px; padding:0 10px; line-height:1.8;">

    <!-- عنوان العقد -->
    <p style="text-align:center; font-size:13px; margin-bottom:10px;"><?= $contract_type ?></p>

    <!-- بيانات العقد -->
    <p>رقم العقد: (<?= $contract_num ?>)</p>
    <p>بتاريخ: <?= $contract_date ?></p>
    <p>تم الإتفاق و التراضي على التعاقد فيما بين كل من:- الطرف الأول: السيد/ <?= $buyer_name ?></p>

    <table width="100%" style="margin-bottom:4px;">
        <tr>
            <td width="50%">هاتف: <?= $buyer_phone ?></td>
            <td width="50%" style="text-align:left;">العنوان: <?= $buyer_address ?></td>
        </tr>
    </table>

    <p>- بطاقة شخصية رقم: <?= $buyer_id ?></p>
    <p>- الطرف الثاني/ دلتا لتكنولوجيا المصاعد و التجارة ش.م.م, رقم السجل التجاري/ 165786</p>

    <table width="100%" style="margin-bottom:4px;">
        <tr>
            <td width="33%">- ويمثلها/ محمود السيد محمد</td>
            <td width="33%" style="text-align:center;">هاتف: 30006374</td>
            <td width="33%" style="text-align:left;">العنوان: سلوى - قطر.</td>
        </tr>
    </table>

    <p>(وتسمى فيما بعد البائع)</p>
    <p>و افـق الـطرفـان باهليتهما الشرعية للتعاقد ومسؤوليتهما الكاملة على تنفيذ بنود الاتفاق كاملا وعدم العدول عنه على النحو التالي:</p>

    <ol style="padding-right:20px;">
        <li style="padding-bottom:6px;">اتفق الطرفان على أن يقوم البائع بتوريد وتركيب عدد (1) مصعد فوجي (بدون غرفة ماكينة) في المبني التابع للمشتري وهو عبارة عن فيلا، ولذلك لحساب المشتري طبقا للشروط والمواصفات المرفقة بهذا العقد ووِرقة المواصفات، والذي يعتبر جُزءً لا يتجزأ منه، ولذلك مقابل ثمن إجمالي، كما مُبين بالفقرة رقم (3).</li>
        <li style="padding-bottom:6px;">أية إضافات قد يطلبها المشتري ينتج عنها تكاليف إضافية يتم الاتفاق عليها في حينه.</li>
        <li style="padding-bottom:6px;">الثمن وطريقة الدفع: يَدفع المشتري القيمة المتفق عليها للبائع بالكيفية التالية:</li>
    </ol>

    <!-- جدول الدفعات -->
    <table width="90%" align="center" style="border-collapse:collapse; margin:8px auto 12px auto;">
        <tr>
            <th style="border:2px solid #000; padding:6px; width:33%;"></th>
            <th style="border:2px solid #000; padding:6px; text-align:center; width:33%;">قيمة المصعد: <?= $price ?> ألف ريال</th>
            <th style="border:2px solid #000; padding:6px; width:33%;"></th>
        </tr>
        <tr>
            <td style="border:2px solid #000; padding:6px; text-align:center;">الدفعات</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;">المبلغ</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;">عدد (<?=count($itmxArr)?>) مصعد <?= $price ?></td>
        </tr>
        <tr>
            <td style="border:2px solid #000; padding:6px; text-align:center;">دفعة اولى</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;"><?= $pay1 ?> ريال قطري</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;">دفعة عند التعاقد</td>
        </tr>
        <tr>
            <td style="border:2px solid #000; padding:6px; text-align:center;">دفعة ثانية</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;"><?= $pay2 ?> ريال قطري</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;">دفعة عند التوريد إلى الموقع</td>
        </tr>
        <tr>
            <td style="border:2px solid #000; padding:6px; text-align:center;">دفعة الثالثة</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;"><?= $pay3 ?> ريال قطري</td>
            <td style="border:2px solid #000; padding:6px; text-align:center;">دفعة عند الإستلام</td>
        </tr>
    </table>

    <p>45000 ريال كُل شي خمسة وأربعون ألف ريال.</p>
    <p>ـ يتم تسديد كافة الدفعات المستحقة بموجب شيكات أو بالإرسال على حساب الشركة.</p>
    <p>حساب الشركة:</p>
    <p>الأيبان: QA93CBQA000000004570373658001</p>

    <!-- بند 4: المواصفات -->

  <?if (count($lftxarr) > 0) {?>
      <p style="margin-top:8px;"><strong>4. يلترم البائع بان يوفر المصاعد بالمواصفات الفنية الاتية:</strong></p>
    <p><strong>اولا: مصعد الركاب:</strong></p>
    <ol style="padding-right:20px; list-style-type:upper-alpha;">
        <li style="padding-bottom:4px;"><strong>نوع الماكينة:</strong> <?= $liftData['a1'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>نوع المصعد:</strong> <?= $liftData['a2'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>بلد المنشأ:</strong> <?= $liftData['a3'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>عدد وقفات المصعد:</strong> <?= $liftData['a4'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>الإشارات:</strong> <?= $liftData['a5'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>سرعة المصعد:</strong> <?= $liftData['a6'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>حمولة الماكينة:</strong> <?= $liftData['a7'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>مقاس بئر المصعد:</strong> <?= $liftData['a8'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>سعة الكابينة:</strong> <?= $liftData['a9'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>نوع وقياس باب المصعد:</strong> <?= $liftData['a10'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>الكبينة:</strong> <?= $liftData['a11'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>نوع الديكور الداخلي:</strong> <?= $liftData['a12'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>نوع أرضية المصعد:</strong> <?= $liftData['a13'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>نوع المرآة:</strong> <?= $liftData['a14'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>سعر الأعمال الميكانيكا:</strong> <?= $liftData['a15'] ?? '' ?></li>
        <li style="padding-bottom:4px;"><strong>سعر الأعمال الكهربائية:</strong> <?= $liftData['a16'] ?? '' ?></li>
    </ol>
  <?}?>

    <!-- بند 5: الصيانة والضمان -->
    <p style="margin-top:8px;"><strong>5. الصيانة و الضمان</strong></p>
    <ol style="padding-right:20px; list-style-type:upper-alpha;">
        <li style="padding-bottom:6px;">عند تسديد الشاري لمستحقات البائع طبقا للمواعد المتفق عليها في هذا العقد، يمنح البائع المشتري صيانة مجانية لمدة عامين.</li>
        <li style="padding-bottom:6px;">الصيانة المجانية مدتها (2 سنة) تشمل قطع الغيار، وتبدأ من تاريخ التشغيل، وبعد انتهاء الصيانة المجانية تكون الصيانة المدفوعة قيمتها (4500 ريال) في العام للمصعد الواحد سنوياً شاملة الصيانة وقطع الغيار وتكون الصيانة كل شهر مره واحدة ومدة 12 مره في السنة.</li>
        <li style="padding-bottom:6px;">في حال تأخر الشاري دفع مبلغ الصيانة السنوية بعد تقديم العقد والفاتورة لمدة ثلاث شهور لا تلتزم الشركة بإجراء أي أعمال صيانة و طوارئ.</li>
        <li style="padding-bottom:6px;">في حالة توقيع عقد الصيانة الضمان (15) سنة على الماكينة وتبدأ من تاريخ التشغيل ولا تشمل الاستعمال السئ، ومربوطة بالقيام باعمال الصيانة الدورية من قبلنا.</li>
        <li style="padding-bottom:6px;">في حالة توقيع عقد الصيانة يلتزم البائع بالحضور في الحالات الطارئة ويتعهد المشتري بان لا يسمح لإي جهة كانت بإجراء أي أعمال سواء كانت تشغيل أو صيانة أو إصلاحات في المصعد وأن يتقيد بإستعماله في الغرض المحدد له في هذا العقد، والمخصص من اجله، وإلا يسقط حقه في الضمان والصيانة.</li>
    </ol>

    <!-- بند 6: أعمال تحضيرية -->
    <p style="margin-top:8px;"><strong>6. أعمال تحضيرية يقوم المشتري بتنفيذها :</strong></p>
    <ol style="padding-right:20px; list-style-type:upper-alpha;">
        <li style="padding-bottom:6px;">يلترم المشتري بتوفير جميع الاعمال الكهربائية (الكيبل(Cable) + الدي بي(DP)+ الايسوليتور) + (Isolator) على مسؤؤليته و نفقته, وذلك حسب المواصفات الخاصة بتوصيلات المصاعد في المباني و عند عدم توفر تيار (الثلاثي الجهد) يتم تركيب ميكانيك المصعد و يتم الاتفاق بين الطرفين على موعد جديد لتشغيل المصعد.</li>
        <li style="padding-bottom:6px;">يلترم المشتري بتوفير جميع الاعمال الانشائية اللازمة قبل وخلال وبعد تركيب المصعد مثلاً لا حصراً: أي تكسير او ثُقوب ناتجة عن تركيب المصعد او لازمة لتركيب المصعد و إجراء أعمال التشطيبات حول ابواب المصعد والسقف بعد الانتهاء من تركيب المصعد، حيث أن مسؤولية البائع هي تركيب وتشغيل المصعد فقط.</li>
    </ol>

    <!-- بند 7: التوريد والتركيب -->
    <p style="margin-top:8px;"><strong>7. التوريد والتركيب:</strong></p>
    <ol style="padding-right:20px; list-style-type:upper-alpha;">
        <li style="padding-bottom:6px;">يتم توريد وتركيب البضاعة المتفق عليها خلال مدة لا تزيد عن 3 أشهر من تاريخ تأكيد الطلب برسالة خطية من قِبل المشتري حسب البند رقم 2، وطلب الاوردر من تاريخ توقيع الزبون على أختيار الكابين ودفع اول دفعه.</li>
        <li style="padding-bottom:6px;">يلتزم البائع بتقديم الاستشارة اللازمة لأعمال بئر المصعد.</li>
    </ol>

    <!-- جدول التركيب -->
    <table width="100%" style="border-collapse:collapse; margin:8px 0 12px 0;">
        <tr>
            <th style="border:2px solid #000; padding:6px; text-align:center;">العمل</th>
            <th style="border:2px solid #000; padding:6px; text-align:center;">المدة</th>
        </tr>
        <tr>
            <td style="border:2px solid #000; padding:6px; text-align:center;">مدة تركيب الميكانيكيا</td>
            <td style="border:2px solid #000; padding:6px;">بعد 1 أسبوع من وصول البضاعة الى الموقع ودفع دفعة الوصول وتكون مدة التركيب 7 ايام.</td>
        </tr>
        <tr>
            <td style="border:2px solid #000; padding:6px; text-align:center;">مدة تركيب الكهرباء والتشغيل</td>
            <td style="border:2px solid #000; padding:6px;">يتم تركيب الاعمال الكهربائية بعد وصول التيار الكهربي 3 فاز الى الموقع وتكون مدة التشغيل 7 أيام.</td>
        </tr>
    </table>

    <!-- بند 8: الشروط والأحكام -->
    <p style="margin-top:8px;"><strong>8. الشروط و الأحكام:</strong></p>
    <ul style="padding-right:20px;">
        <li style="padding-bottom:6px;">
            لا يتلزم البائع بإنهاء العمل في المواعيد المحددة وفقا للفقرات أدناه:
            <ul style="padding-right:15px; margin-top:4px;">
                <li style="padding-bottom:4px;">❖ إذا تأخر المشتري بتنفيذ المباني وعدم تسليمها للبائع.</li>
                <li style="padding-bottom:4px;">❖ إذا تأخر المشتري في دفع أي قسط من الأقساط المستحقة المتفق عليها.</li>
                <li style="padding-bottom:4px;">❖ إذا تأخر المشتري في توصيل التيار الكهربائي اللازم للتركيب والتشغيل في غرفة الماكينات.</li>
            </ul>
        </li>
        <li style="padding-bottom:6px;">عند انتهاء البائع من التركيب الكامل، يقوم بإشعار المشتري بذلك، لإستلام المصعد رسميا ودفع رصيد الحساب وذلك حسب الاتفاق في البند رقم (2) وتبدأ عندئذ مدة الصيانة المجانية بعد تشغيل المصعد مباشرة.</li>
        <li style="padding-bottom:6px;">لا يحق للمشتري أو غيره التصرف في المصعد أو أي جزء من بضاعته بأية طريقة من طرق الاستخدام أو نقل الملكية أو إجراء أي رهن عليه ما دام لم يسدد كامل ثمنه للبائع كما لا يحق للغير، إيا كان، توقيع أي حجوزات عليه. ويكون المصعد ملك للشركة لحين سداد كامل المبلغ.</li>
        <li style="padding-bottom:6px;">الشركة غير مسئولة عن أي تأخير في الشحن بسبب "الحرب" القائمة.</li>
    </ul>

    <!-- بند 9: الاعمال المدنية -->
    <p style="margin-top:8px;"><strong>9. الاعمال المدنية وتعليمات التركيب والتشغيل:</strong></p>
    <ul style="padding-right:20px;">
        <li style="padding-bottom:6px;">أبواب المصاعد تكون بمقاس ثابت ولذلك يفضل عدم عمل التشطيبات إلا بعد تركيب ابواب المصعد، وأعمال التشطيبات هي مسؤولية المالك.</li>
        <li style="padding-bottom:6px;">الكيبل اللازم للمصعد يجب أن يكون مستقل عن المجمع الرئيسي ولا يُؤخذ منه توصيلات لاي أجهزة أخرى داخل المنزل.</li>
        <li style="padding-bottom:6px;">الرجاء ابلاغ الشركة قبل شهر من توصيل الكهرباء لحجز فريق لتركيب الكهرباء.</li>
    </ul>

    <!-- البنود 10-13 -->
    <p style="padding-bottom:6px;">10- يُصبح هذا العقد نافذا بمجرد التوقيع عليه من الطرفين، ولا يجوز للمشتري إلغاءه. إلا بموافقة من البائع مالم يتم البدء في تصنيع المصعد سوف تقوم الشركة بخصم قيمة الدفعة الأولى بالكامل.</p>
    <p style="padding-bottom:6px;">11- اتخذ الطرفين محل إقامة لهما في العنوان الموضح في هذا العقد وفي حالة تغييره يلتزم الطرف الذي قام بالتغيير بإبلاغ الطريق الآخر فورا وخطياً، من أجل تأمين وصول المراسلات المتبادلة بين الطرفين.</p>
    <p style="padding-bottom:6px;">12- أي خلاف ينشأ بين الطرفين بخصوص هذا العقد، يجري حله ودياً وفي حال عدم الإتفاق، يؤخذ بحكم المحاكم القطرية المختصة.</p>
    <p style="padding-bottom:6px;">13- حرر هذا العقد من نسختين أصليتين، استلم كل فريق نسخة للعمل بموجبها بعد أن يتم توقيعهما من الفريقين.</p>

    <!-- ملاحظة -->
    <p style="margin-top:8px;"><strong>ملاحظة:</strong></p>
    <p>ـ يقوم الطرف الثاني بتوريد وتركب السقالات و كل ما يخص التركيب من ادوات هي مسئولية الطرف الثاني وليس على الطرف الأول أي التزامات نحو التركيب.</p>

    <!-- والله ولي التوفيق -->
    <p style="text-align:center; margin-top:15px; margin-bottom:20px;">والله ولي التوفيق,,,</p>

    <!-- التوقيعات -->
    <table width="100%" style="margin-top:10px;">
        <tr>
            <td width="50%" style="vertical-align:top;">
                <p><strong>المشتري</strong></p>
                <p>السيد/ <?= $buyer_name ?></p>
                <p>التوقيع:</p>
              <?if (isset($_GET['sign'])) {
              $signUrl = "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/IIP_Contracts/signature_{$contractId}.png";
              $signLocal = __DIR__ . '/tmp/sign_' . $contractId . '.png';
              file_put_contents($signLocal, file_get_contents($signUrl));
              ?>
                <img src="<?= $signLocal ?>" style="width:100px; height:auto;">
              <?}?>
            </td>
            <td width="50%" style="vertical-align:top; text-align:left;">
                <p><strong>البائع</strong></p>
                <p>الساده/ دلتا لتكنولوجيا المصاعد و التجارة ش.م.م</p>
                <p>التوقيع: _______________</p>
            </td>
        </tr>
    </table>

</div>
