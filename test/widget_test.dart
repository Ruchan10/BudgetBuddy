Flexible(
  flex: 1,
  child: TextField(
    focusNode: _amountFocusNode,
    controller: _amountController,
    keyboardType: TextInputType.number,
    onChanged: (value) {
      setState(() {
        _isPositive = !value.startsWith('-');
      });
    },
    onSubmitted: (_) {
      // Trigger focus to category and open dropdown after a small delay
      FocusScope.of(context).requestFocus(_categoryFocusNode);
      Future.delayed(const Duration(milliseconds: 150), () {
        final dropdown = _categoryFocusNode.context?.findRenderObject();
        if (dropdown != null) {
          // Simulate a tap to open dropdown
          GestureBinding.instance.handlePointerEvent(
            PointerDownEvent(position: Offset.zero),
          );
        }
      });z
    },
    decoration: InputDecoration(
      hintText: 'Amount',
      prefixIcon: GestureDetector(
        onTap: () {
          setState(() {
            _isPositive = !_isPositive;
          });
        },
        child: Container(
          alignment: Alignment.center,
          width: 40,
          child: Text(
            _isPositive ? "+" : "-",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isPositive ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _isPositive ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _isPositive ? Colors.green : Colors.red,
          width: 2.5,
        ),
      ),
    ),
  ),
),
