<?php
        $con_string = "host=localhost port=5432 dbname=spark user=christian password=foca";
        $conn = pg_connect($con_string);
        $query = "select * from gc_obter_velocidades();";
        $result=pg_query($conn, $query);
        if  (!$result) {
                echo "error";
        }
        else if (pg_num_rows($result) == 0) {
                echo "0 records";
        }
        else{
                while ($row = pg_fetch_array($result)) {
                        echo $row[0];
                }
        }
        pg_close($conn);
?>
