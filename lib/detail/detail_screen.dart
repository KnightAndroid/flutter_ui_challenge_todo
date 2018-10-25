import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_todo/category_icon.dart';
import 'package:flutter_todo/category_info.dart';
import 'package:flutter_todo/create/create_screen.dart';
import 'package:flutter_todo/data_provider.dart';
import 'package:flutter_todo/detail/todo_item.dart';
import 'package:flutter_todo/model.dart';

class DetailScreen extends StatefulWidget {
  final Category category;

  const DetailScreen({Key key, this.category}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  bool creatingTask = false;

  AnimationController _transitionAnimation;
  Tween<double> buttonSizeTween;
  Tween<double> buttonPositionTween;
  Tween<double> buttonRadiusTween;

  double buttonSize = 48.0;
  double buttonRadius = 48.0;
  double buttonPosition = 16.0;

  Tween<double> listOpacityTween;
  Tween<double> createOpacityTween;

  double listOpacity;
  double createOpacity;

  String newTaskTitle;

  @override
  void initState() {
    _transitionAnimation =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() => setState(() {
                buttonSize = buttonSizeTween.evaluate(_transitionAnimation);
                buttonPosition =
                    buttonPositionTween.evaluate(_transitionAnimation);
                buttonRadius = buttonRadiusTween.evaluate(_transitionAnimation);

                listOpacity = listOpacityTween.evaluate(_transitionAnimation);
                createOpacity =
                    createOpacityTween.evaluate(_transitionAnimation);
              }))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                creatingTask = !creatingTask;
              });
            }
          });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            _buildContent(),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  _startTransitionAnimation() {
    final width = MediaQuery.of(context).size.width;
    buttonSizeTween = Tween(begin: 48.0, end: width);
    buttonPositionTween = Tween(begin: 16.0, end: 0.0);
    buttonRadiusTween = Tween(begin: 48.0, end: 0.0);

    listOpacityTween = Tween(begin: 1.0, end: 0.0);
    createOpacityTween = Tween(begin: 0.0, end: 1.0);

    if (creatingTask) {
      buttonSizeTween = ReverseTween(buttonSizeTween);
      buttonPositionTween = ReverseTween(buttonPositionTween);
      buttonRadiusTween = ReverseTween(buttonRadiusTween);

      listOpacityTween = ReverseTween(listOpacityTween);
      createOpacityTween = ReverseTween(createOpacityTween);
    }

    _transitionAnimation.forward(from: 0.0);
  }

  _buildContent() {
    if (_transitionAnimation.isAnimating) {
      return Stack(
        children: <Widget>[
          Opacity(
            opacity: createOpacity,
            child: _buildCreate(),
          ),
          Opacity(
            opacity: listOpacity,
            child: _buildTaskList(),
          ),
        ],
      );
    }

    if (creatingTask) {
      return _buildCreate();
    }
    return _buildTaskList();
  }

  _buildTaskList() {
    return Container(
      padding: const EdgeInsets.all(80.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Hero(
            tag: "categoryIcon${widget.category.title}",
            child: CategoryIcon(
              icon: widget.category.icon,
              color: widget.category.color,
            ),
          ),
          SizedBox(
            height: 32.0,
          ),
          Hero(
              tag: "categoryInfo${widget.category.title}",
              child: CategoryInfo(category: widget.category)),
          SizedBox(
            height: 24.0,
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: 1.0,
              child: StoreConnector<CategoryState, List<Task>>(
                  converter: (store) => store.state.categories
                      .firstWhere(
                          (category) => category.id == widget.category.id)
                      .tasks,
                  builder: (context, tasks) {
                    return ListView.builder(
                      itemBuilder: (BuildContext context, int index) {
                        final task = tasks[index];
                        return TodoItem(category: widget.category, task: task);
                      },
                      itemCount: tasks.length,
                    );
                  }),
              duration: Duration(milliseconds: 300),
            ),
          )
        ],
      ),
    );
  }

  _buildButton() {
    return Positioned(
      bottom: buttonPosition,
      right: buttonPosition,
      child: Container(
        width: buttonSize,
        height: 48.0,
        decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.purple,
            borderRadius: BorderRadius.circular(buttonRadius)),
        child: StoreConnector<CategoryState, VoidCallback>(
          converter: (store) =>
              () => store.dispatch(AddTask(widget.category, newTaskTitle)),
          builder: (context, callback) => IconButton(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (creatingTask) {
                    callback();
                  }
                  _startTransitionAnimation();
                },
              ),
        ),
      ),
    );
  }

  _buildCreate() {
    return CreateScreen(
      category: widget.category,
      taskChanged: (value) => newTaskTitle = value,
      onClose: _startTransitionAnimation,
    );
  }
}
