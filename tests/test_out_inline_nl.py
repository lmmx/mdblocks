text = "1\n2,3\n4,5,6\n"
lines = text.rstrip("\n").split("\n")
numbers = []
for l in lines:
    for i in l.split(","):
        numbers.append(int(i))
print(f"{len(numbers)} numbers: {numbers}")
