fact(n, m){
  return 1+n%m;
}

main{
  var n;
  var m;

  read n;
  read m;
  write fact(n, m);
  writeln;
}
