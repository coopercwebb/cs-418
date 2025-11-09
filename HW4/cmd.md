
```erlang
hw4_lib:sim_len_ms(100, 100000, 10000, hw4_lib:expDist(1.0), hw4_lib:expDist(1.0)).

hw4_lib:sim_len_ms(100, 100000, 10000, hw4_lib:expDist(1.0), hw4_lib:constDist(1.0)).

hw4_lib:sim_len_ms(100, 100000, 10000, hw4_lib:expDist(1.0),  hw4_lib:erlangDist(1.0, 5)).
```
