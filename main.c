f1(n){
  return 1+n;
}

main {

  var n, a, b, i;
  
  label flag:
  read n;

  if n > 10 then
    goto flag;
  endif;

  for i := 0; i < n; i := i + 1 {
    write i%3;
  }
  writeln;

  switch n {
    case 0: write 500; break;
    case 1: write 600; break;
    default: write n^2; break;
  }
  writeln;

  read a;
  read b;

  if n == a && n == b then
    write 1;
  else
    write 0;
  endif;

  if n > a || n > b then
    write 1;
  else
    write 0;
  endif;

  if !(n > a) then
    write 1;
  else
    write 0;
  endif;
  writeln;

  write a++;
  write ++a;
  write b--;
  write --b;
  writeln;
  
}
