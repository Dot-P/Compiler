fact(n, m){
  return n^m^2;
}

main{
  var n;
  var m;

  read n;
  read m;
  goto A;
  write 0;
  A: 
  write fact(n, m);
  writeln;
}
