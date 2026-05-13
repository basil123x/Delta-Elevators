<?
include("../xtras/config.php");
$cont = $conx->query("SELECT bookings.orderId , bookings.date , cust_app.a1 FROM bookings JOIN cust_app ON bookings.uid = cust_app.a3 WHERE bookings.id = '$batchId'")->fetch_assoc();
$orderx = $conx->query("SELECT bookings.floors , bookings.persons , COUNT(orders.itmid) AS Items , bookings.orderId FROM bookings LEFT JOIN orders ON bookings.orderId = orders.oid WHERE bookings.orderId = '".$cont['orderId']."'")->fetch_assoc();
$batchArr = array();
$batches = $conx->query("SELECT Batches.id , Batches.batch , Batches.notes FROM bookings LEFT JOIN Batches ON bookings.id = Batches.bookingId WHERE bookings.id = '$batchId' AND batch IS NOT NULL AND notes IS NOT NULL");
while($rows=mysqli_fetch_array($batches)) {$batchArr[] = $rows;}
?>

<div class="content" style="margin:0 43px;">
    <h2 style="text-align:center;">عرض السعر</h2>
    <div style="font-weight:bold;">عرض الرقم: <?=explode('-',$cont['date'])[0];?>/<?=$cont['orderId'];?></div>
    <div style="font-weight:bold;">التاريخ: <span dir="ltr"><?= date('Y-m-d', strtotime($cont['date'])); ?></span></div>
    <div style="font-weight:bold;">إلى الفاضل: <?=$cont['a1'];?></div>

    <div style="font-weight:bold;">السلام عليكم...</div>
    <div style="font-weight:bold;">نشكركم على التواصل معنا وفخورين بأن نقدم لكم عرض سعر مصعد بجودة عالية وفائقة ويتناسب تماما مع المبنى الخاص بكم.</div>
    <div style="font-weight:bold;">لقد قمنا برفع مقاسات بيت المصعد والابعاد الفنية كما هو مذكور في المواصفات , ولمزيد من المعلومات والتوضيحات يجب الاتصال بنا .</div>
    <div style="font-weight:bold;">نشكركم ونؤكد لكم اهتمامنا بخدمتكم في أي وقت.</div>
    <div style="font-weight:bold;">مع تحيات,,,,,,,</div>
    <div style="height:100px;"></div>
    <div style="text-align:center;font-weight:bold;">"شركة دلتا لتكنولوجيا المصاعد والتجارة وياك في كل مكان"</div>
    <div style="text-align:center;font-weight:bold;text-decoration: underline;">*الشركة معتمدة لدى الدفاع المدني , وحاصلة على شهادة إعتماد منتج من الدفاع المدني*</div>
    <div style="height:330px;"></div>
    <div style="text-align:center;font-weight:bold;text-decoration: underline;">الموضوع: عرض مصعد جديد</div>
    <div style="font-weight:bold;">بناء على رغبتكم , يسرنا أن نقدم لكم عرضنا لتوريد وتركيب مصعد كهربائي فوجي للركاب وذلك حسب الأتي:</div>
    <table style="width:100%;" cellpadding="5px" cellspacing="0px">
        <tr>
            <td style="border:1px solid #000;text-align:center;">نوع المصعد: V.V.V.F</td>
            <td style="border:1px solid #000;text-align:center;">منظم السرعات</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">عدد المصاعد</td>
            <td style="border:1px solid #000;text-align:center;"><?=$orderx['Items'];?></td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">عدد الأشخاص</td>
            <td style="border:1px solid #000;text-align:center;"><?=$orderx['persons'];?></td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">الوزن (كجم) (الحمل) </td>
            <td style="border:1px solid #000;text-align:center;">630 kg</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">سعة الشفت (سم)</td>
            <td style="border:1px solid #000;text-align:center;">حسب الخرائط</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">السرعة (م/ث)</td>
            <td style="border:1px solid #000;text-align:center;">0.4 m/s</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">عدد الوقفات</td>
            <td style="border:1px solid #000;text-align:center;"><?=$orderx['floors'];?></td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;">سعر المصعد ماكينة فوجي</td>
            <td style="border:1px solid #000;text-align:center;">105000 ألف ريال قطري</td>
        </tr>
    </table>

    <div style="font-weight:bold;margin-top:30px;">مواصفات المصعد: </div>

    <table style="width:100%;" cellpadding="5px" cellspacing="0px">
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">1</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">المصعد</td>
            <td style="border:1px solid #000;padding:8px;">مصنوع طبقاً للمواصفات والمقاييس الأوروبية (EN-81 20-50) والعالمية (ISO 9001)</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">2</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">نوع الماكينة</td>
            <td style="border:1px solid #000;padding:8px;">فوجي</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">3</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">ماكينة الباب</td>
            <td style="border:1px solid #000;padding:8px;">وتسمى الهيدر</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">4</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الريل</td>
            <td style="border:1px solid #000;padding:8px;">وهي السكك الحديدية ع شكل حرف T</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">5</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الحبال</td>
            <td style="border:1px solid #000;padding:8px;">وهي نوع من الفولاذ جوستاف وألف</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">6</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الإضاءة</td>
            <td style="border:1px solid #000;padding:8px;">حسب طلب الزبون</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">7</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">نوع وقياس باب المصعد</td>
            <td style="border:1px solid #000;padding:8px;">عرض فتحة الباب (حسب الخرائط) الارتفاع (حسب الخرائط)</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">8</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الكابينة</td>
            <td style="border:1px solid #000;padding:8px;">بانوراما ذهبي - (304) والأرضية رخام</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">9</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">سعة الكابينة</td>
            <td style="border:1px solid #000;padding:8px;">حسب الخرائط</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">10</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">عمق البنر</td>
            <td style="border:1px solid #000;padding:8px;">مطلوب 1000 مم</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">11</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الباب</td>
            <td style="border:1px solid #000;padding:8px;">حسب الخرائط</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">12</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">نوع الديكور الداخلي</td>
            <td style="border:1px solid #000;padding:8px;">بانوراما ذهبي</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">13</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">نوع الأرضية</td>
            <td style="border:1px solid #000;padding:8px;">رخام</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">14</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">نوع الكابينة</td>
            <td style="border:1px solid #000;padding:8px;">مصعد بانوراما</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">15</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">سنسر</td>
            <td style="border:1px solid #000;padding:8px;">كامل * انتركوم لكل طابق</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">16</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الأزرار</td>
            <td style="border:1px solid #000;padding:8px;">لوحة أزرار لجميع الأدوار</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">17</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">إضافات</td>
            <td style="border:1px solid #000;padding:8px;">جرس إنذار — لوحة خارجية أعلى باب المصعد</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">18</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الشاشة</td>
            <td style="border:1px solid #000;padding:8px;">شاشة لكل دور</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">19</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">زر الاتصال</td>
            <td style="border:1px solid #000;padding:8px;">زر لاستدعاء المصعد بكل طابق</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">20</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الصيانة</td>
            <td style="border:1px solid #000;padding:8px;">2 سنة صيانة مجانية شاملة قطع الغيار، تبدأ من تاريخ استلام المصعد</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">21</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الصيانة السنوية</td>
            <td style="border:1px solid #000;padding:8px;">(4500) ريال شاملة قطع الغيار، تبدأ بعد انتهاء الصيانة المجانية</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">22</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">جهاز الحالات الطارئة</td>
            <td style="border:1px solid #000;padding:8px;">جهاز الحالات الطارئة حيث يعمل المصعد اوتوماتيكياً ويصل الكابينة الى أقرب دور ويفتح الأبواب تلقائياً</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">23</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">أمان الكهرباء</td>
            <td style="border:1px solid #000;padding:8px;">دائرة أمان كهربائية لمنع تحرك الكابينة خلال تواجد أحد الأبواب مفتوحاً</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">24</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">منظم السرعة</td>
            <td style="border:1px solid #000;padding:8px;">منظم أوتوماتيكي للسرعة أثناء هبوط الكابينة</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">25</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">حماية المحرك</td>
            <td style="border:1px solid #000;padding:8px;">قاطع حراري لحماية المحرك</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">26</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الكنترول</td>
            <td style="border:1px solid #000;padding:8px;">جهاز الكنترول داخل خزانة مقاومة للغبار تحتوي الأجهزة الإلكترونية والكهربائية</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">27</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">ممتص الصدمات</td>
            <td style="border:1px solid #000;padding:8px;">وجود مصدّات في أسفل البنر حسب المواصفات العالمية لتخفيف الصدمات</td>
        </tr>
        <tr style="background:#f9f9f9;">
            <td style="border:1px solid #000;text-align:center;padding:8px;">28</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">الضمان</td>
            <td style="border:1px solid #000;padding:8px;">الضمان (15) سنوات على الماكينة وعلى شوانب الصنع والتركيب ويجب ان تسدد كامل الدفعات ليتحقق مشروع الضمان والكفالة، ويتم تسليم المصعد اللى المالك عن طريق كتاب خطي عند الانتهاء من كافة الاعمال ويعتبر تاريخ تسليم المصعد هو بداية الصيانة المجانية والضمان</td>
        </tr>
        <tr>
            <td style="border:1px solid #000;text-align:center;padding:8px;">29</td>
            <td style="border:1px solid #000;padding:8px;font-weight:bold;">بطارية طوارئ</td>
            <td style="border:1px solid #000;padding:8px;">يحتوي المصعد على بطارية ARD تعمل عند انقطاع الكهرباء عند المصعد تقف عند أقرب طابق وتفتح أبواب المصعد</td>
        </tr>
    </table>
    <div style="height:150px;"></div>
    <div style="font-weight:bold;">مدة التسليم والتركيب</div>
    <div style="font-weight:bold;">1- التسليم والتركيب خلال (4) ثلث أشهر من تاريخ الموافقة الخطية على عرض الأسعار واختيار الكبائن لمطلوبة</div>
    <div style="font-weight:bold;text-decoration: underline;">أعمال تحضيرية يقوم المشتري بتنفيذها:</div>
    <div style="font-weight:bold;margin-top:20px;">1. يلتزم المشتري بتوفير جميع الاعمال الكهربائية (الكيلو(Cable) + الدي بي(DP) + الابسوليتور)+ على مسؤولياته ونفقاته، وذلك حسب المواصفات الخاصة بتوصيلات المصاعد في المباني وعند عدم توفر تيار (الثلاثي الجهد) يتم تركيب ميكانيك المصعد ويتم الاتفاق بين الطرفين على موعد جديد لتشغيل المصعد.</div>
    <div style="font-weight:bold;margin-top:20px;">2. يلتزم المشتري بتوفير جميع الاعمال الانشائية اللازمة قبل وخلال وبعد تركيب المصعد مثلا لا حصرا: أي تكسير أو تقوب ناتجة عن تركيب المصعد أو لازمة لتركيب المصعد وإجراء أعمال التشطيبات حول ابواب المصعد والسقف بعد الانتهاء من تركيب المصعد، حيث أن مسئولية البائع هي تركيب وتشغيل المصعد فقط.</div>
    <div style="font-weight:bold;margin-top:20px;">3. يسلم المشتري للبائع، دون مقابل مخزنا مقفلاً ومناسباً في موقع التركيب قرب بئر المصعد يتسع لحفظ اجزاء المصاعد وأدوات التركيب الخاصة بالبائع، ويعاد هذا المخزن للمشتري بعد إتمام التركيب. وإذا اضطر المشتري تسهيل الأعماله، إلى نقل البضاعة إلى مخزن آخر بالمواقع يقوم البائع بالنقل على نفقة المشتري ولا يجوز للمشتري أو أي من الغير فتح هذا المخزن وأجراء أي تغيير أو نقل في البضاعة دون موافقة البائع المسبقة والخطية، وألا تكون قيمة القطع الناقصة أو التالفة وكذلك الضرر اللاحق بالبائع على عاتق المشتري.</div>
    <div style="font-weight:bold;margin-top:20px;">4. في حالة اختيار المصعد بغرفة ماكينة يلتزم المشتري بدفع قيمة الرافعة (Crane).</div>
    <div style="font-weight:bold;margin-top:20px;">طريقة الدفع: </div>
     <table style="width:100%;" cellpadding="5px" cellspacing="0px">
        <tr>
            <td style="border:1px solid #000;font-weight:bold;">S.N.O.</td>
            <td style="border:1px solid #000;font-weight:bold;">نسبة الدفعات %</td>
            <td style="border:1px solid #000;font-weight:bold;">المبلغ</td>
            <td style="border:1px solid #000;font-weight:bold;">ملاحظات</td>
        </tr>
        <?$i=1;foreach ($batchArr as $rx) {?>
            <tr>
                <td style="border:1px solid #000;font-weight:bold;"><?=$i;?></td>
                <td style="border:1px solid #000;font-weight:bold;"><?=$rx['batch'];?>%</td>
                <td style="border:1px solid #000;font-weight:bold;"></td>
                <td style="border:1px solid #000;font-weight:bold;"><?=$rx['notes'];?></td>
            </tr>
        <?$i++;}?>

    </table>
    <div style="height:20px;"></div>
    <div style="font-weight:bold;">2- السعر أعلاه يتضمن فقط الأجزاء والمواصفات المذكورة في العرض كما سبق وأي تعديل أو إضافة يستوجب إعادة التسعير</div>
    <div style="font-weight:bold;">3- إن أسعارنا تبقى صالحة لمدة ثلاثون (30) يوماً من تاريخه ويحتاج بعدها إلى إعادة تأكيد من قبلنا</div>
    <div style="height:120px;"></div>
    <div style="font-weight:bold;text-align:center;">وتفضلوا بقبول فائق الإحترام,</div>
    <div style="height:20px;"></div>
    <div style="display:flex; flex-direction:row; gap:20px;">
    
        <div style="flex:1; text-align:right;">
            <div style="font-weight:bold;">موافقة المالك:</div>
            <div style="margin-top:10px;">
                <table style="margin-right: auto; margin-left: 0; direction: rtl;">
                    <tr>
                        <td style="padding:4px;">
                            <label style="display:flex; align-items:center; gap:8px; cursor:pointer;">
                                <input type="checkbox" name="owner_approval" value="موافق" style="width:18px; height:18px; cursor:pointer;">
                                <span>موافق</span>
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:4px;">
                            <label style="display:flex; align-items:center; gap:8px; cursor:pointer;">
                                <input type="checkbox" name="owner_approval" value="غير موافق" style="width:18px; height:18px; cursor:pointer;">
                                <span>غير موافق</span>
                            </label>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <!-- شمال: بيانات الشركة -->
        <div style="flex:1; text-align:center;">
            <div style="font-weight:bold;">دلتا لتكنولوجيا المصاعد والتجارة ش.م.م</div>
            <div style="font-weight:bold; margin-top:8px;">مقدم من المهندس: محمد رأفت</div>
            <div style="font-weight:bold; margin-top:8px;">هاتف: 77710600</div>
        </div>

    </div>
</div> 





<!-- <div style="display:flex;flex-direction:column;">
            <span style="font-weight:bold;">موافقة المالك</span>
            <div>
                <div class="select-checkbox" style="border:2px solid #000;width:20px;height:20px;"></div>
            </div>
        </div>
        <div style="display:flex;flex-direction:column;">
            <span style="font-weight:bold;">موافقة المالك</span>
            <div>
                <div class="select-checkbox" style="border:2px solid #000;width:20px;height:20px;"></div>
            </div>
        </div> -->