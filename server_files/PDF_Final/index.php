<?
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once 'vendor/autoload.php';

$mpdf = new \Mpdf\Mpdf([
    'mode'          => 'ar',
    'format'        => 'A4',
    'tempDir' => sys_get_temp_dir(),
    'fontDir'       => [__DIR__ . '/fonts/'],
    'fontdata'      => [
        'cairo' => [
            'R'          => 'Cairo-Regular-fixed.ttf',
            'B'          => 'Cairo-Bold-fixed.ttf',
            'useOTL'     => 0xFF,
            'useKashida' => 75,
        ]
    ],
    'default_font'  => 'cairo',
    'margin_top'    => 40,
    'margin_bottom' => 25,
    'margin_left'   => 10,
    'margin_right'  => 10,
    'margin_header' => 5,
    'margin_footer' => 5,
]);

$mpdf->SetDirectionality('rtl');
$mpdf->SetWatermarkImage('img/logo.png', 0.1, [120, 120]);
$mpdf->showWatermarkImage = true;
// الهيدر والفوتر
$header = '<table width="100%" style=" padding-bottom:8px;"><tr><td><img src="img/header.png" height="100"/></td></tr></table>';
$footer = '<div style="border-top:2px solid #CE2020; text-align:center; font-family:cairo; font-size:9px; padding-top:5px; direction:rtl;">+974 4006 4365 | sales@deltatechnologys.com<br>Salwa Road, Building 32, Doha - Qatar</div>';

$mpdf->SetHTMLHeader($header);
$mpdf->SetHTMLFooter($footer);

// ← هنا بتجيب المحتوى من ملف خارجي
ob_start();
include('content.php');
$html = ob_get_clean();

$mpdf->WriteHTML($html);
$mpdf->Output('contract.pdf', 'I');