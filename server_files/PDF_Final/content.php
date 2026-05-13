<?
$ktype = "";
$batchId = "";
if (isset($_GET['ktype']))
{
    $ktype = $_GET['ktype'];
}

if (isset($_GET['batchId']))
{
    $batchId = $_GET['batchId'];
}

$page = "";

switch ($ktype) {
    case '1':
        $page = "IIP_Contract";
        break;
    case '2':
        $page = "Quotation_Contract";
        break;
    case '3':
        $page = "Completed_Contract";
        break;
    default:
        break;
}

include('pages/'.$page.'.php');

?> 