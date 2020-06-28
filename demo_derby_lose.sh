source bashrc_mdblock_functions.sh

>&2 echo "💥 Oh no ! ! ! 💥"
pybtickblock -c "h = 'horse'; e = 'ever'; hh, diz, x, ow, bigbag = ('🐎💨','😵','❌','🌵🤕🌵','💰'); inwam = f'I n{e} win any money... {bigbag.join([x*3]*2)}'; stupid_h = f'Stupid {h} I just fell out of the P{h[1:-1]}che... {ow}'; ohno = [f'Racing {h}s at the derby {hh*3}', f'Why am I n{e} getting lucky? {diz}', *[inwam]*2, stupid_h]; raise ValueError('\n'.join(ohno))"
