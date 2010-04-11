var $files = [];
XMLHttpRequest.prototype.send = function (data) {
    return this.sendAsBinary(data);
};

function filesSelected(files) {
    for (var i = 0; i < files.length; i++) {
        var file = files[i];
        $files.push(file);

        var reader = new FileReader();
        reader.onload = function(event){
            var img = document.createElement('img');
            img.src = reader.result;
            img.width = img.height = 32;
            $('#preview').append(img);
            upload(event);
        };
        reader.readAsDataURL(file);
     };
}
function onFileOver(e) {
    e.preventDefault();
    e.stopPropagation();
}
function onFileDrop(e) {
    e.preventDefault();
    e.stopPropagation();

    filesSelected(e.dataTransfer.files);
}
function upload(e){
    e.preventDefault();
    e.stopPropagation();

    for (var i = 0; i < $files.length; i++){
        var file = $files[i];
        var reader = new FileReader();
        reader.onload = function(event){
            $.ajax({
                url : '/upload',
                type : 'post',
                data : reader.result,
                dataType : 'json',
                success : function(data){
                    $.each(data, function(index,elem){
                        if (elem.match(/saved as (.*)$/)) {
                            var m = RegExp.$1;
                            $('<a>').attr('href', '/' + m).text(m).wrap('<p>').appendTo('#response');
                        } else {
                            $('<p>').text(elem).appendTo('#response');
                        }
                    });
                    $('.indexes').show();
                }
            });
        };
        reader.readAsBinaryString(file);
    }
}

$(document).ready(function(){
    $('.indexes').hide();
});