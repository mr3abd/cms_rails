popupwindow = (url, title, w, h)->
  left = (screen.width/2)-(w/2);
  top = (screen.height/2)-(h/2);
  return window.open(url, title, 'toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=no, resizable=no, copyhistory=no, width='+w+', height='+h+', top='+top+', left='+left);





$(document).on "click", ".share-link", (e)->
  e.preventDefault()
  $link = $(this)
  w = $link.attr("window-width")
  h = $link.attr("window-height")
  url = $link.attr("href")
  title = $link.attr("window-title")

  popupwindow(url, title, w, h)


