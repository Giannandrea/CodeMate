Title: Registration

# Registration

<script>
var licensees = TextMate.licensees;
if(licensees) { document.write("This copy of CodeMate is registered to " + licensees + "."); }
else          { document.write("This copy of CodeMate is unregistered. <a href='#' onClick='javascript:TextMate.addLicense();'>Add license.</a>"); }
</script>
