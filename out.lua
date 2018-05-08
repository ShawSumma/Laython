require "python"

py_assign_tuple = list({py_list({int({py_int(4)}), list({py_list({int({py_int(5)}), int({py_int(6)})})})})})["py_data"]
x = py_assign_tuple[1]
y = py_assign_tuple[2]
z = py_assign_tuple[3]
py_load(print, "print")({py_load(x, "x"), py_load(y, "y"), py_load(z, "z")},{})
