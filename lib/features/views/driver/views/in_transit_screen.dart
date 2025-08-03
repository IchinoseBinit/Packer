import 'package:flutter/material.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/driver/controller/driver_controller.dart';
import 'package:packer/features/views/driver/model/driver_transfer_model.dart';
import 'package:packer/features/views/driver/widgets/driver_transfer_card.dart';
import 'package:provider/provider.dart';

class InTransitScreen extends StatefulWidget {
  const InTransitScreen({super.key});

  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("In Transit"),
      ),
      body: Padding(
        padding: AppConstants.padding,
        child: FutureBuilder<List<DriverTransferModel>>(
          future: Provider.of<DriverController>(context, listen: false)
              .getInTransitTransfers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No transfers found"),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return DriverTransferCard(
                  transferItem: snapshot.data![index],
                  fromTransit: true,
                  needAction: false ,
                  callback: () {
                    Provider.of<DriverController>(context, listen: false)
                        .onDetailsFromInTransit(context, snapshot.data![index]);
                  },
                );
              },
            );
          }
        ),
      ),
    );
  }
}