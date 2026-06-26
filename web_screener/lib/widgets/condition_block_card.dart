import 'package:flutter/material.dart';
import '../models/condition_block.dart';
import '../providers/strategy_provider.dart';
import 'indicator_search_sheet.dart';
import 'package:provider/provider.dart';
import 'indicator_config_sheet.dart';

class ConditionBlockCard extends StatelessWidget {
  final ConditionBlock block;
  final VoidCallback onRemove;
  final Function(ConditionBlock) onUpdate;
  final bool isFirst;

  final Color? accentColor;

  const ConditionBlockCard({
    super.key,
    required this.block,
    required this.onRemove,
    required this.onUpdate,
    this.isFirst = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Deep Slate for inset effect
        borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFirst)
            _buildLabel('IF', accentColor ?? const Color(0xFF828DF8))
          else
            _buildTypeDropdown(context),
          const SizedBox(width: 12),
          
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Left Node
                ..._buildExpressionWidgets(context, block.leftNode, (updatedNode) {
                  block.leftNode = updatedNode;
                  onUpdate(block);
                }),
                
                // 2. Operator
                _buildOperatorDropdown(
                  context: context,
                  value: block.operator == 'Select...' ? null : block.operator,
                  onChanged: (val) {
                    if (val != null) {
                      block.operator = val;
                      onUpdate(block);
                    }
                  },
                ),

                // 3. Right Node
                if (block.operator != 'Select...') ...[
                  ..._buildExpressionWidgets(context, block.rightNode, (updatedNode) {
                    block.rightNode = updatedNode;
                    onUpdate(block);
                  }),
                  if (block.operator == 'Between') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Text('and', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ..._buildExpressionWidgets(context, block.rightNode2 ?? ValueNode(0.0), (updatedNode) {
                      block.rightNode2 = updatedNode;
                      onUpdate(block);
                    }),
                  ],
                ],
              ],
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 16),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildTypeDropdown(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor ?? const Color(0xFF828DF8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: block.type,
          dropdownColor: Theme.of(context).cardColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          items: const [
            DropdownMenuItem(value: 'AND', child: Text('AND')),
            DropdownMenuItem(value: 'OR', child: Text('OR')),
          ],
          onChanged: (val) {
            if (val != null) {
              block.type = val;
              onUpdate(block);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOperatorDropdown({
    required BuildContext context,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Condition', style: TextStyle(color: Colors.white38, fontSize: 13)),
          dropdownColor: Theme.of(context).cardColor,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
          items: const [
            'Between',
            'Crosses Above',
            'Crosses Below',
            'Is Greater Than',
            'Is Less Than',
            'Is Equal To',
            'Increased by %',
            'Decreased by %',
          ].map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<Widget> _buildExpressionWidgets(BuildContext context, ExpressionNode node, Function(ExpressionNode) onUpdate) {
    final List<Widget> widgets = [];
    final String nodeType = node is IndicatorNode 
        ? 'INDICATOR' 
        : node is ValueNode ? 'VALUE' : 'MATH';

    if (node is MathNode) {
      widgets.add(const Text('(', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)));
    }

    // Type Toggle
    widgets.add(
      Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: nodeType,
            dropdownColor: Theme.of(context).cardColor,
            style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold),
            items: const [
              DropdownMenuItem(value: 'VALUE', child: Text('VALUE')),
              DropdownMenuItem(value: 'INDICATOR', child: Text('INDICATOR')),
              DropdownMenuItem(value: 'MATH', child: Text('MATH')),
            ],
            onChanged: (val) {
              if (val != null && val != nodeType) {
                if (val == 'INDICATOR') {
                  onUpdate(IndicatorNode(ConfigurableIndicator(name: 'Select Indicator')));
                } else if (val == 'VALUE') {
                  onUpdate(ValueNode(0.0));
                } else if (val == 'MATH') {
                  onUpdate(MathNode(
                    left: ValueNode(0.0),
                    operator: '+',
                    right: ValueNode(0.0),
                  ));
                }
              }
            },
          ),
        ),
      )
    );

    // Content
    if (node is IndicatorNode) {
      widgets.add(_buildIndicatorButton(context, node.indicator, onUpdate));
    } else if (node is ValueNode) {
      widgets.add(
        SizedBox(
          width: 70,
          height: 30,
          child: _ManagedTextField(
            initialValue: node.value.toString(),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) {
                onUpdate(ValueNode(parsed));
              }
            },
          ),
        )
      );
    } else if (node is MathNode) {
      widgets.addAll(_buildExpressionWidgets(context, node.left, (updated) {
        onUpdate(MathNode(left: updated, operator: node.operator, right: node.right));
      }));
      widgets.add(
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: node.operator,
              dropdownColor: Theme.of(context).cardColor,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              items: ['+', '-', '*', '/'].map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
              onChanged: (val) {
                if (val != null) {
                  onUpdate(MathNode(left: node.left, operator: val, right: node.right));
                }
              },
            ),
          ),
        )
      );
      widgets.addAll(_buildExpressionWidgets(context, node.right, (updated) {
        onUpdate(MathNode(left: node.left, operator: node.operator, right: updated));
      }));
    }

    if (node is MathNode) {
      widgets.add(const Text(')', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)));
    }

    return widgets;
  }

  Widget _buildIndicatorButton(BuildContext context, ConfigurableIndicator indicator, Function(ExpressionNode) onUpdate) {
    final isUnset = indicator.name == 'Select...' || indicator.name == 'Select Indicator' || indicator.name.isEmpty;
    final strategyProvider = context.watch<StrategyProvider>();
    final baseTimeframe = strategyProvider.currentStrategy.baseTimeframe;
    final isMultiTimeframe = strategyProvider.currentStrategy.isMultiTimeframe;

    void openSearchThenConfig() async {
      final selectedName = await IndicatorSearchSheet.show(context);
      if (selectedName == null) return;

      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;

      final newIndicator = ConfigurableIndicator(
        name: selectedName,
        parameters: ConfigurableIndicator.getDefaultParameters(selectedName),
      );

      if (!context.mounted) return;
      IndicatorConfigSheet.show(
        context,
        newIndicator,
        strategyProvider.currentStrategy.exchange,
        (updated) => onUpdate(IndicatorNode(updated)),
        onReset: () => onUpdate(IndicatorNode(ConfigurableIndicator(name: 'Select...'))),
        isMultiTimeframe: isMultiTimeframe,
      );
    }

    return InkWell(
      onTap: () {
        if (isUnset) {
          openSearchThenConfig();
        } else {
          IndicatorConfigSheet.show(
            context,
            indicator,
            strategyProvider.currentStrategy.exchange,
            (updated) => onUpdate(IndicatorNode(updated)),
            onChange: openSearchThenConfig,
            onReset: () => onUpdate(IndicatorNode(ConfigurableIndicator(name: 'Select...'))),
            isMultiTimeframe: isMultiTimeframe,
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isUnset ? 'Select Indicator' : indicator.getFriendlyLabel(baseTimeframe),
              style: TextStyle(
                color: isUnset ? Colors.white38 : Colors.white,
                fontSize: 13,
                fontWeight: isUnset ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(isUnset ? Icons.arrow_drop_down : Icons.settings, color: Colors.white70, size: 12),
          ],
        ),
      ),
    );
  }
}

class _ManagedTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ManagedTextField({required this.initialValue, required this.onChanged});

  @override
  State<_ManagedTextField> createState() => _ManagedTextFieldState();
}

class _ManagedTextFieldState extends State<_ManagedTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _ManagedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      final currentNum = double.tryParse(_controller.text);
      final newNum = double.tryParse(widget.initialValue);
      if (currentNum != null && newNum != null && currentNum == newNum) {
        // The values are mathematically equal (e.g. user typed "7", but initialValue became "7.0")
        // Don't overwrite the text field, let the user keep typing.
        return;
      }
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        hintText: 'Value',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: TextInputType.text,
      onChanged: widget.onChanged,
    );
  }
}


