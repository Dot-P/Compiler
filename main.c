fact(n, m){
  return n+m;
}

main{
  var n;

  label a:
  read n;
  if n > 10 then
    write 0;
  else
    goto a;
  endif;

  writeln;
}
