import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
import 'package:packer/features/views/widgets/file_upload.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class RackProductList extends StatefulWidget {
  const RackProductList({super.key});

  @override
  State<RackProductList> createState() => _RackProductListState();
}

class _RackProductListState extends State<RackProductList> {
  @override
  Widget build(BuildContext context) {
    final damageProductController =
        Provider.of<DamageProductController>(context, listen: false);

    final productList = damageProductController.rackProductList;
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: Text("Rack Product List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Text(
                  "Product List",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 15.h),
                ListView.builder(
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        fileUpload(context, productList[index].id);
                        // Handle tap if needed
                      },
                      child: ListTile(
                        title: Text(productList[index].name),
                        subtitle:
                            Text("Quantity: ${productList[index].quantity}"),
                        trailing: Text("ID: ${productList[index].id}"),
                      ),
                    );
                  },
                  itemCount: productList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
