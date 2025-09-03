/*=============================================================
  Authour URI: www.binarytheme.com
  License: Commons Attribution 3.0

  http://creativecommons.org/licenses/by/3.0/

  100% Free To use For Personal And Commercial Use.
  IN EXCHANGE JUST GIVE US CREDITS AND TELL YOUR FRIENDS ABOUT US
 
  ======================================================== */

(function ($) {
  "use strict";
  var mainApp = {
    slide_fun: function () {
            // Verifica se o elemento existe antes de iniciar o carrossel
      if ($('#carousel-example').length) {
        $('#carousel-example').carousel({
          interval: 3000 // THIS TIME IS IN MILLI SECONDS
        });
      }
    },
    dataTable_fun: function () {
            // Verifica se o elemento existe antes de iniciar o dataTable
      if ($('#dataTables-example').length) {
        $('#dataTables-example').dataTable();
      }
    },
   
    custom_fun: function () {
      /*====================================
      WRITE YOUR  SCRIPTS BELOW
      ======================================*/
            // Esta função não precisa retornar nada para funcionar.
    }
  };
 
 
  $(document).ready(function () {
    mainApp.slide_fun();
    mainApp.dataTable_fun();
    mainApp.custom_fun();
  });
}(jQuery));